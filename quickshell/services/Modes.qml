pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: modes
    property bool caffeineActive: false
    property bool dndActive: false
    function setCaffeine(on: bool): void {
        modes.caffeineActive = on;
        Notifs.notify({app: "caffeine", summary: on ? "Caffeine on" : "Caffeine off", syncId: "caffeine", timeout: Theme.osdTimeout});
    }
    function toggleCaffeine(): void {
        if (!modes.caffeineActive) {
            caffeineCheck.running = true;
            return;
        }
        modes.setCaffeine(false);
    }
    function toggleDnd(): void {
        modes.dndActive = !modes.dndActive;
        Notifs.notify({app: "dnd", summary: modes.dndActive ? "DND on" : "DND off", syncId: "dnd", timeout: Theme.osdTimeout});
    }
    property bool bluelightActive: false
    function setBluelight(on: bool): void {
        modes.bluelightActive = on;
        Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", on ? "4000" : "6000"]);
        Notifs.notify({app: "bluelight", summary: on ? "Bluelight on" : "Bluelight off", syncId: "bluelight", timeout: Theme.osdTimeout});
    }
    function toggleBluelight(): void {
        modes.setBluelight(!modes.bluelightActive);
    }
    Process {
        id: inhibitProc
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Quickshell", "--why=Caffeine mode", "sleep", "infinity"]
        running: modes.caffeineActive
        onExited: exitCode => {
            if (modes.caffeineActive && exitCode !== 0) {
                modes.caffeineActive = false;
                Notifs.notify({app: "caffeine", summary: "Caffeine failed", body: "inhibitor exited, turned off", timeout: Theme.osdTimeout});
            }
        }
    }
    Process {
        id: caffeineCheck
        command: ["sh", "-c", "command -v systemd-inhibit >/dev/null"]
        onExited: exitCode => {
            if (caffeineCheck.running)
                return;
            if (exitCode !== 0)
                Notifs.notify({app: "caffeine", summary: "Caffeine unavailable", body: "systemd-inhibit not found", timeout: Theme.osdTimeout});
            else if (!modes.caffeineActive)
                modes.setCaffeine(true);
        }
    }
    Process {
        id: staleLockCleanup
        command: ["sh", "-c", "pkill -f -- '[s]ystemd-inhibit.*--who=Quickshell.*sleep infinity'"]
        Component.onCompleted: staleLockCleanup.running = true
    }
}
