import QtQuick
import Quickshell
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

    property var mainScreen: Services.Settings.mainScreen(Quickshell.screens)
    screen: bar.mainScreen

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
    readonly property var exclusivePopups: [calendarPopup, controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, settingsPopup, launcherPopup, clipboardPopup, emojiPopup]
    function hideAll(list): void {
        for (const p of list)
            p.visible = false;
    }
    function openExclusive(target, returnTo = null): void {
        const open = !target.visible;
        hideAll(exclusivePopups);
        target.returnTo = open ? returnTo : null;
        target.visible = open;
        if (open && target.useGrab !== false && typeof target.regrab === "function")
            target.regrab();
    }
    function toggleCalendar(): void {
        openExclusive(calendarPopup);
    }
    function toggleControl(): void {
        openExclusive(controlPanelPopup);
    }
    function toggleWifi(): void {
        openExclusive(wifiPopup);
    }
    function openWifiFromPanel(): void {
        openExclusive(wifiPopup, controlPanelPopup);
    }
    function toggleBluetooth(): void {
        openExclusive(bluetoothPopup);
    }
    function openBluetoothFromPanel(): void {
        openExclusive(bluetoothPopup, controlPanelPopup);
    }
    function togglePower(): void {
        openExclusive(powerPopup);
    }
    function openPowerFromPanel(): void {
        openExclusive(powerPopup, controlPanelPopup);
    }
    function openSettingsFromPanel(): void {
        openExclusive(settingsPopup, controlPanelPopup);
    }
    function toggleSettings(): void {
        openExclusive(settingsPopup);
    }
    function toggleLauncher(): void {
        openExclusive(launcherPopup);
    }
    function toggleClipboard(): void {
        openExclusive(clipboardPopup);
    }
    function toggleEmoji(): void {
        openExclusive(emojiPopup);
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
        const popups = [controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, settingsPopup, historyPanel];
        let bottom = 0;
        for (const p of popups) {
            if (p.visible && p.height > 0)
                bottom = Math.max(bottom, top + (p.extraTop ?? 0) + p.height);
        }
        return bottom;
    }
    property int rightPopupWidth: {
        const popups = [controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, settingsPopup, historyPanel];
        let w = 0;
        for (const p of popups) {
            if (p.visible)
                w = Math.max(w, p.width);
        }
        return w > 0 ? w : Services.Theme.popupWidth;
    }
    function closePopups(): void {
        hideAll(exclusivePopups);
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

    Workspaces {}
    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }
    Clock {
        bar: bar
        clockSource: systemClock
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
        BatteryIcon {}
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            BellIcon {
                bar: bar
            }
            PowerIcon {
                bar: bar
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

    GlobalShortcut { appid: "qs-bar"; name: "Toggle Power Menu"; description: "Open the power menu"; onPressed: bar.togglePower() }
    GlobalShortcut { appid: "qs-bar"; name: "Power Key"; description: "Handle the power key per settings"; onPressed: bar.handlePowerKey() }
    GlobalShortcut { appid: "qs-bar"; name: "Toggle Control Panel"; description: "Open the control panel"; onPressed: bar.toggleControl() }
    GlobalShortcut { appid: "qs-bar"; name: "Toggle Launcher"; description: "Open the application launcher"; onPressed: bar.toggleLauncher() }
    GlobalShortcut { appid: "qs-bar"; name: "Toggle Clipboard"; description: "Open the clipboard history picker"; onPressed: bar.toggleClipboard() }
    GlobalShortcut { appid: "qs-bar"; name: "Toggle Emoji"; description: "Open the emoji picker"; onPressed: bar.toggleEmoji() }
    GlobalShortcut { appid: "qs-bar"; name: "Settings"; description: "Open settings"; onPressed: bar.toggleSettings() }
    GlobalShortcut { appid: "qs-bar"; name: "Lock Screen"; description: "Lock the session"; onPressed: bar.lockScreen() }
    GlobalShortcut { appid: "qs-bar"; name: "Screenshot Area"; description: "Screenshot a selected area"; onPressed: bar.screenshot("area") }
    GlobalShortcut { appid: "qs-bar"; name: "Screenshot Full"; description: "Screenshot the full screen"; onPressed: bar.screenshot("full") }
    GlobalShortcut { appid: "qs-bar"; name: "Screenshot Window"; description: "Screenshot the active window"; onPressed: bar.screenshot("window") }
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
