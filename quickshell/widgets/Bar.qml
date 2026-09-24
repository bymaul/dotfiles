import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Hyprland._GlobalShortcuts
import Quickshell.Wayland
import "../popups"
import "../services" as Services
PanelWindow {
    id: bar

    required property var lockContext
    required property var sessionLock
    required property var screenshotTool

    anchors {
        top: true
        left: true
        right: true
    }

    readonly property string focusedName: Hyprland.focusedMonitor?.name ?? ""
    property var mainScreen: Services.Settings.mainScreen(Quickshell.screens)
    screen: bar.mainScreen ?? Quickshell.screens[0] ?? null
    readonly property string mainName: bar.mainScreen && bar.mainScreen.name ? bar.mainScreen.name : ""

    function currentPopupAnchor(): var {
        const anchor = Services.Settings.barForScreen(bar.focusedName);
        return anchor ?? bar;
    }
    function syncBarReg(): void {
        Services.Settings.unregisterBar(bar);
        if (bar.mainName !== "")
            Services.Settings.registerBar(bar.mainName, bar);
    }
    Component.onCompleted: bar.syncBarReg()
    Component.onDestruction: Services.Settings.unregisterBar(bar)
    onMainNameChanged: bar.syncBarReg()

    implicitHeight: Services.Theme.barHeight
    exclusiveZone: implicitHeight
    color: Services.Theme.barBg
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: Services.Theme.border
    }
    WlrLayershell.namespace: "qs-bar"
    // Single source of truth for popup routing. exclusivePopups omits
    // historyPanel (it follows the control panel instead of competing
    // with it); rightPopups is the right-anchored subset used for the
    // notification parking offset.
    readonly property var allPopups: [calendarPopup, controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, settingsPopup, launcherPopup, clipboardPopup, emojiPopup, historyPanel]
    readonly property var exclusivePopups: [calendarPopup, controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, settingsPopup, launcherPopup, clipboardPopup, emojiPopup]
    readonly property var rightPopups: [calendarPopup, controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, settingsPopup, historyPanel]
    function popupByName(name: string): var {
        switch (name) {
        case "calendar": return calendarPopup;
        case "control": return controlPanelPopup;
        case "wifi": return wifiPopup;
        case "bluetooth": return bluetoothPopup;
        case "power": return powerPopup;
        case "settings": return settingsPopup;
        case "launcher": return launcherPopup;
        case "clipboard": return clipboardPopup;
        case "emoji": return emojiPopup;
        default: return null;
        }
    }
    function closePopups(): void {
        for (const p of exclusivePopups)
            p.visible = false;
    }
    function togglePopup(name: string): void {
        const target = bar.popupByName(name);
        if (target)
            openExclusive(target);
    }
    function openFromPanel(name: string): void {
        const target = bar.popupByName(name);
        if (target)
            openExclusive(target, controlPanelPopup);
    }
    function openExclusive(target, returnTo = null): void {
        const open = !target.visible;
        bar.closePopups();
        if (open) {
            if (returnTo && returnTo.anchor && returnTo.anchor.window)
                target.anchor.window = returnTo.anchor.window;
            else
                target.anchor.window = bar.currentPopupAnchor();
        }
        target.returnTo = open ? returnTo : null;
        target.visible = open;
        if (open && target.useGrab !== false && typeof target.regrab === "function")
            target.regrab();
    }
    function toggleCalendar(): void {
        bar.togglePopup("calendar");
    }
    function toggleControl(): void {
        bar.togglePopup("control");
    }
    function toggleWifi(): void {
        bar.togglePopup("wifi");
    }
    function openWifiFromPanel(): void {
        bar.openFromPanel("wifi");
    }
    function toggleBluetooth(): void {
        bar.togglePopup("bluetooth");
    }
    function openBluetoothFromPanel(): void {
        bar.openFromPanel("bluetooth");
    }
    function togglePower(): void {
        bar.togglePopup("power");
    }
    function openPowerFromPanel(): void {
        bar.openFromPanel("power");
    }
    function openSettingsFromPanel(): void {
        bar.openFromPanel("settings");
    }
    function toggleSettings(): void {
        bar.togglePopup("settings");
    }
    function toggleLauncher(): void {
        bar.togglePopup("launcher");
    }
    function toggleClipboard(): void {
        bar.togglePopup("clipboard");
    }
    function toggleEmoji(): void {
        bar.togglePopup("emoji");
    }
    function lockScreen(): void {
        bar.closePopups();
        lockContext.reset();
        sessionLock.locked = true;
    }
    function handlePowerKey(): void {
        const action = Services.Settings.powerButtonAction;
        if (action === "lock") {
            bar.lockScreen();
        } else if (action === "suspend") {
            Services.Power.lock();
            bar.closePopups();
            Quickshell.execDetached(["systemctl", "suspend", "-i"]);
        } else if (action === "poweroff") {
            bar.closePopups();
            Quickshell.execDetached(["systemctl", "poweroff", "-i"]);
        } else if (action === "ignore") {
            return;
        } else {
            bar.togglePower();
        }
    }
    function screenshot(mode: string): void {
        screenshotTool.capture(mode);
    }
    property int rightPopupBottom: {
        const top = Services.Theme.popupTopGap;
        const popups = bar.rightPopups;
        let bottom = 0;
        for (const p of popups) {
            if (p.visible && p.height > 0)
                bottom = Math.max(bottom, top + (p.extraTop ?? 0) + p.height);
        }
        return bottom;
    }
    property int rightPopupWidth: {
        const popups = bar.rightPopups;
        let w = 0;
        for (const p of popups) {
            if (p.visible)
                w = Math.max(w, p.width);
        }
        return w > 0 ? w : Services.Theme.popupWidth;
    }
    function followPopupAnchor(): void {
        const anchor = bar.currentPopupAnchor();
        const all = bar.allPopups;
        for (const p of all) {
            if (!p || !p.anchor || p.anchor.window === anchor)
                continue;
            // historyPanel.visible is a binding (panel.visible && history.length);
            // never leave a plain assignment behind: hide, move, rebind.
            if (p === historyPanel) {
                if (!p.visible) {
                    p.anchor.window = anchor;
                } else {
                    p.visible = false;
                    p.anchor.window = anchor;
                    p.rebindVisibility();
                }
                continue;
            }
            if (!p.visible) {
                p.anchor.window = anchor;
                continue;
            }
            p.visible = false;
            p.anchor.window = anchor;
            p.visible = true;
            if (typeof p.regrab === "function")
                p.regrab();
        }
    }
    Connections {
        target: Hyprland
        function onFocusedMonitorChanged(): void {
            bar.followPopupAnchor();
        }
        function onFocusedWorkspaceChanged(): void {
            bar.followPopupAnchor();
        }
    }
    onScreenChanged: bar.closePopups()
    readonly property int screenCount: Quickshell.screens.length
    onScreenCountChanged: {
        bar.closePopups();
        Services.Settings.refreshMonitors(true);
    }
    function revealHistory(i: int): void {
        historyPanel.revealAt(i);
    }
    function panelStep(dir: int): void {
        controlPanelPopup.stepVertical(dir);
    }
    function panelActivate(): void {
        controlPanelPopup.activateSelected();
    }

    Process {
        id: depCheck
        command: ["sh", "-c", "for b in cliphist wl-copy hyprctl jq brightnessctl notify-send systemd-inhibit hypridle upower loginctl; do command -v \"$b\" >/dev/null || printf '%s\\n' \"$b\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const missing = text.trim().split("\n").filter(s => s !== "");
                if (missing.length === 0)
                    return;
                console.warn("quickshell: missing helper binaries: " + missing.join(", "));
                if (missing.includes("notify-send"))
                    return;
                Quickshell.execDetached(["notify-send", "-a", "quickshell", "-t", "8000", "-i", "dialog-warning-symbolic", "Missing helper binaries", missing.join(", ")]);
            }
        }
        Component.onCompleted: depCheck.running = true
    }

    WindowTitle {
        screenName: bar.mainName
    }
    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }
    Workspaces {
        id: workspaces
        screenName: bar.mainName
    }
    Row {
        id: systemStatus
        anchors {
            right: parent.right
            rightMargin: Services.Theme.popupMargin
            verticalCenter: parent.verticalCenter
        }
        spacing: Services.Theme.groupSpacing
        Tray {}
        SystemGroup {
            bar: bar
        }
        BatteryIcon {
            bar: bar
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Services.Theme.groupSpacing
            BellIcon {
                bar: bar
            }
            Clock {
                bar: bar
                clockSource: systemClock
            }
        }
    }

    CalendarPopup {
        id: calendarPopup
        bar: bar
        clock: systemClock
    }

    ControlPanelPopup {
        id: controlPanelPopup
        bar: bar
        historyWindow: historyPanel
    }

    NotificationHistoryPopup {
        id: historyPanel
        bar: bar
        panel: controlPanelPopup
    }

    WifiPopup {
        id: wifiPopup
        bar: bar
    }

    BluetoothPopup {
        id: bluetoothPopup
        bar: bar
    }

    PowerPopup {
        id: powerPopup
        bar: bar
    }

    SettingsPopup {
        id: settingsPopup
        bar: bar
    }

    LauncherPopup {
        id: launcherPopup
        bar: bar
    }

    ClipboardPopup {
        id: clipboardPopup
        bar: bar
    }

    EmojiPopup {
        id: emojiPopup
        bar: bar
    }

    function unlocked(): bool {
        return !(bar.sessionLock && bar.sessionLock.locked === true);
    }

    GlobalShortcut { appid: "qs-bar"; name: "Toggle Power Menu"; description: "Open the power menu"; onPressed: { if (bar.unlocked()) bar.togglePower(); } }
    GlobalShortcut { appid: "qs-bar"; name: "Power Key"; description: "Handle the power key per settings"; onPressed: bar.handlePowerKey() }
    GlobalShortcut { appid: "qs-bar"; name: "Toggle Control Panel"; description: "Open the control panel"; onPressed: { if (bar.unlocked()) bar.toggleControl(); } }
    GlobalShortcut { appid: "qs-bar"; name: "Toggle Launcher"; description: "Open the application launcher"; onPressed: { if (bar.unlocked()) bar.toggleLauncher(); } }
    GlobalShortcut { appid: "qs-bar"; name: "Toggle Clipboard"; description: "Open the clipboard history picker"; onPressed: { if (bar.unlocked()) bar.toggleClipboard(); } }
    GlobalShortcut { appid: "qs-bar"; name: "Toggle Emoji"; description: "Open the emoji picker"; onPressed: { if (bar.unlocked()) bar.toggleEmoji(); } }
    GlobalShortcut { appid: "qs-bar"; name: "Settings"; description: "Open settings"; onPressed: { if (bar.unlocked()) bar.toggleSettings(); } }
    GlobalShortcut { appid: "qs-bar"; name: "Lock Screen"; description: "Lock the session"; onPressed: bar.lockScreen() }
    GlobalShortcut { appid: "qs-bar"; name: "Screenshot Area"; description: "Screenshot a selected area"; onPressed: { if (bar.unlocked()) bar.screenshot("area"); } }
    GlobalShortcut { appid: "qs-bar"; name: "Screenshot Full"; description: "Screenshot the full screen"; onPressed: { if (bar.unlocked()) bar.screenshot("full"); } }
    GlobalShortcut { appid: "qs-bar"; name: "Screenshot Window"; description: "Screenshot the active window"; onPressed: { if (bar.unlocked()) bar.screenshot("window"); } }
    GlobalShortcut { appid: "qs-bar"; name: "Toggle Caffeine"; description: "Toggle caffeine mode (block idle)"; onPressed: Services.Modes.toggleCaffeine() }
    GlobalShortcut { appid: "qs-bar"; name: "Toggle DND"; description: "Toggle do-not-disturb mode"; onPressed: Services.Modes.toggleDnd() }
    GlobalShortcut { appid: "qs-bar"; name: "Volume Up"; description: "Raise the volume"; onPressed: Services.Media.volumeUp() }
    GlobalShortcut { appid: "qs-bar"; name: "Volume Down"; description: "Lower the volume"; onPressed: Services.Media.volumeDown() }
    GlobalShortcut { appid: "qs-bar"; name: "Volume Mute"; description: "Mute the volume"; onPressed: Services.Media.toggleVolumeMute() }
    GlobalShortcut { appid: "qs-bar"; name: "Mic Mute"; description: "Mute the microphone"; onPressed: Services.Media.toggleMicMute() }
    GlobalShortcut { appid: "qs-bar"; name: "Media Play/Pause"; description: "Play or pause media"; onPressed: Services.Media.mediaToggle() }
    GlobalShortcut { appid: "qs-bar"; name: "Media Next"; description: "Next media track"; onPressed: Services.Media.mediaNext() }
    GlobalShortcut { appid: "qs-bar"; name: "Media Previous"; description: "Previous media track"; onPressed: Services.Media.mediaPrev() }
    GlobalShortcut { appid: "qs-bar"; name: "Brightness Up"; description: "Raise the brightness"; onPressed: Services.Media.brightnessUp() }
    GlobalShortcut { appid: "qs-bar"; name: "Brightness Down"; description: "Lower the brightness"; onPressed: Services.Media.brightnessDown() }
}
