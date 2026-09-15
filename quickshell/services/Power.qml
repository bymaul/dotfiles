pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import "../Palette.js" as Palette

Singleton {
    id: power

    readonly property var lidOptions: ["suspend", "lock", "ignore"]
    readonly property var buttonOptions: ["menu", "suspend", "lock", "poweroff", "ignore"]
    readonly property var criticalOptions: ["suspend", "hibernate", "poweroff", "lock", "notify"]
    readonly property var profileOptions: ["keep", "powersaver", "balanced", "performance"]

    property var battery: (UPower.devices?.values ?? []).find(device => device && device.isLaptopBattery) ?? null
    readonly property bool hasBattery: power.battery != null
    readonly property real level: power.battery?.percentage ?? 0
    readonly property int pct: Math.round(power.level * 100)
    readonly property bool charging: power.hasBattery && (power.battery.state === UPowerDeviceState.Charging || power.battery.state === UPowerDeviceState.FullyCharged || power.battery.state === UPowerDeviceState.PendingCharge)
    readonly property bool discharging: power.hasBattery && !power.charging
    readonly property bool onBattery: UPower.onBattery

    property bool lowFired: false
    property bool criticalFired: false
    property bool actionFired: false
    property bool seenValid: false

    onPctChanged: power.evaluate()
    onChargingChanged: power.evaluate()
    onHasBatteryChanged: power.evaluate()

    Connections {
        target: Settings
        function onLowBatteryPctChanged(): void {
            power.evaluate();
        }
        function onCriticalBatteryPctChanged(): void {
            power.evaluate();
        }
        function onCriticalBatteryActionChanged(): void {
            power.evaluate();
        }
        function onLoadedChanged(): void {
            power.evaluate();
        }
    }

    function evaluate(): void {
        if (!Settings.loaded)
            return;
        if (!power.hasBattery || power.charging) {
            power.lowFired = false;
            power.criticalFired = false;
            power.actionFired = false;
            return;
        }
        if (!power.discharging)
            return;
        if (power.pct > 0)
            power.seenValid = true;
        if (!power.seenValid)
            return;
        const p = power.pct;
        const low = Settings.lowBatteryPct;
        const crit = Math.min(Settings.criticalBatteryPct, low);
        if (!power.lowFired && p <= low) {
            power.lowFired = true;
            Notifs.notify({app: "power", summary: "Low battery " + p + "%", body: "Plug in the charger", icon: "battery-low-symbolic", value: p, syncId: "battery", timeout: 8000});
        }
        if (!power.criticalFired && p <= crit) {
            power.criticalFired = true;
            Notifs.notify({app: "power", summary: "Critical battery " + p + "%", body: power.actionLabel(Settings.criticalBatteryAction), icon: "battery-caution-symbolic", urgency: NotificationUrgency.Critical, syncId: "battery", timeout: 15000});
        }
        if (!power.actionFired && p <= crit) {
            power.actionFired = true;
            power.runCriticalAction();
        }
    }

    function actionLabel(action: string): string {
        if (action === "hibernate")
            return "Hibernating now";
        if (action === "poweroff")
            return "Shutting down now";
        if (action === "lock")
            return "Locking now";
        if (action === "notify")
            return "Plug in the charger";
        return "Suspending now";
    }

    function lock(): void {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function runCriticalAction(): void {
        const action = Settings.criticalBatteryAction;
        if (action === "notify" || action === "lock") {
            if (action === "lock")
                power.lock();
            return;
        }
        const cmd = action === "hibernate" ? "hibernate" : action === "poweroff" ? "poweroff" : "suspend";
        power.lock();
        Quickshell.execDetached(["systemctl", cmd, "-i"]);
    }

    function fmtDur(sec: real): string {
        const m = Math.round(sec / 60);
        if (m < 60)
            return m + "m";
        return Math.floor(m / 60) + "h " + (m % 60) + "m";
    }

    readonly property string statusLine: {
        if (!power.hasBattery)
            return "No battery";
        let s = power.pct + "% · " + (power.charging ? "Charging" : "Discharging");
        const t = power.charging ? power.battery.timeToFull : power.battery.timeToEmpty;
        if (t > 60)
            s += " · " + power.fmtDur(t) + (power.charging ? " to full" : " left");
        return s;
    }

    property bool lidPresent: false
    property bool lidClosed: false
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: lidProbe.running = true
    }
    Process {
        id: lidProbe
        command: ["sh", "-c", "cat /proc/acpi/button/lid/*/state 2>/dev/null || echo missing"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.includes("missing")) {
                    power.lidPresent = false;
                    return;
                }
                power.lidPresent = true;
                power.lidClosed = text.includes("closed");
            }
        }
    }

    property bool xfceBlocking: false
    function refreshInhibitors(): void {
        inhibCheck.running = true;
    }
    Process {
        id: inhibCheck
        command: ["sh", "-c", "systemd-inhibit --list --no-legend 2>/dev/null | grep -i xfce || exit 1"]
        onExited: exitCode => {
            power.xfceBlocking = exitCode === 0;
        }
        Component.onCompleted: inhibCheck.running = true
    }

    property bool profilesAvailable: false
    property string acProfile: ""
    readonly property bool hasPerformanceProfile: PowerProfiles.hasPerformanceProfile
    readonly property string profileName: {
        if (!power.profilesAvailable)
            return "";
        const p = PowerProfiles.profile;
        if (p === PowerProfile.Performance)
            return "performance";
        if (p === PowerProfile.PowerSaver)
            return "powersaver";
        return "balanced";
    }
    function setProfileByName(name: string, quiet: bool): void {
        if (!power.profilesAvailable)
            return;
        if (name !== "powersaver" && name !== "balanced" && name !== "performance")
            return;
        if (name === "performance" && !PowerProfiles.hasPerformanceProfile) {
            Notifs.notify({app: "power", summary: "No performance profile", body: "This system only offers balanced / power-saver", syncId: "power-profile", timeout: Palette.osdTimeout});
            return;
        }
        PowerProfiles.profile = name === "performance" ? PowerProfile.Performance : name === "powersaver" ? PowerProfile.PowerSaver : PowerProfile.Balanced;
        if (!quiet)
            Notifs.notify({app: "power", summary: "Profile: " + name, syncId: "power-profile", timeout: Palette.osdTimeout});
    }
    function cycleProfile(): void {
        const order = ["balanced", "powersaver", "performance"];
        let i = order.indexOf(power.profileName);
        for (let n = 0; n < order.length; n++) {
            i = (i + 1) % order.length;
            if (order[i] !== "performance" || PowerProfiles.hasPerformanceProfile) {
                power.setProfileByName(order[i], false);
                return;
            }
        }
    }
    function cycleAutoProfile(): void {
        const opts = power.profileOptions;
        const i = opts.indexOf(Settings.powerProfileOnBattery);
        Settings.setPowerProfileOnBattery(opts[(i + 1 + opts.length) % opts.length]);
    }
    function applyAutoProfile(): void {
        if (!power.profilesAvailable)
            return;
        const pref = Settings.powerProfileOnBattery;
        if (UPower.onBattery) {
            if (pref === "keep" || pref === power.profileName)
                return;
            if (power.profileName !== "")
                power.acProfile = power.profileName;
            power.setProfileByName(pref, true);
        } else if (power.acProfile !== "") {
            const back = power.acProfile;
            power.acProfile = "";
            power.setProfileByName(back, true);
        }
    }
    Connections {
        target: UPower
        function onOnBatteryChanged(): void {
            power.applyAutoProfile();
        }
    }
    Process {
        id: ppProbe
        command: ["sh", "-c", "command -v powerprofilesctl >/dev/null && exit 0; test -f /usr/share/dbus-1/system-services/org.freedesktop.UPower.PowerProfiles.service"]
        onExited: exitCode => {
            power.profilesAvailable = exitCode === 0;
            if (exitCode === 0)
                power.applyAutoProfile();
        }
        Component.onCompleted: ppProbe.running = true
    }
}
