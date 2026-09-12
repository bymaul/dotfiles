//@ pragma IconTheme Adwaita

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Hyprland._GlobalShortcuts
import Quickshell.Wayland
import Quickshell.Networking
import "widgets"
import "popups"
import "services" as Services
import "Palette.js" as Palette

ShellRoot {
    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 34
        exclusiveZone: implicitHeight

        color: Palette.barBg

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            height: 1
            color: Palette.border
        }

        WlrLayershell.namespace: "qs-bar"

        function openExclusive(target): void {
            const open = !target.visible;

            calendarPopup.visible = false;
            controlPanelPopup.visible = false;
            wifiPopup.visible = false;
            bluetoothPopup.visible = false;
            powerPopup.visible = false;
            passwordDialog.visible = false;
            launcherPopup.visible = false;
            clipboardPopup.visible = false;

            target.visible = open;
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
        function toggleBluetooth(): void {
            openExclusive(bluetoothPopup);
        }
        function togglePower(): void {
            openExclusive(powerPopup);
        }

        function toggleLauncher(): void {
            openExclusive(launcherPopup);
        }

        function toggleClipboard(): void {
            openExclusive(clipboardPopup);
        }

        property int rightPopupBottom: {
            const top = Palette.popupTopGap;
            const popups = [controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup];
            let bottom = 0;

            for (const p of popups) {
                if (p.visible)
                    bottom = Math.max(bottom, top + p.height);
            }

            return bottom;
        }

        function closePopups(): void {
            calendarPopup.visible = false;
            controlPanelPopup.visible = false;
            wifiPopup.visible = false;
            bluetoothPopup.visible = false;
            powerPopup.visible = false;
            passwordDialog.visible = false;
            launcherPopup.visible = false;
            clipboardPopup.visible = false;
        }

        function showPasswordDialog(network): void {
            // The dialog must own keyboard focus alone, or a grabber
            // underneath steals typed passwords.
            wifiPopup.visible = false;
            passwordDialog.network = network;
            passwordDialog.visible = true;
        }

        function closePasswordAndControl(): void {
            passwordDialog.visible = false;
            controlPanelPopup.visible = false;
        }

        // One grab for panel + history + toasts, so toast clicks
        // never close the panel. Deferred activation (see BasePopup).
        HyprlandFocusGrab {
            id: panelGrab

            windows: [controlPanelPopup, historyPanel, toastStack]

            // A clear also fires on non-click hides, so close ONLY
            // our own windows, never a newly opened popup.
            onCleared: controlPanelPopup.visible = false
        }

        Timer {
            interval: 100
            running: controlPanelPopup.visible
            repeat: false

            onTriggered: panelGrab.active = true
        }

        Connections {
            target: controlPanelPopup

            function onVisibleChanged(): void {
                if (!controlPanelPopup.visible)
                    panelGrab.active = false;
            }
        }

        function revealHistory(i: int): void {
            historyPanel.revealAt(i);
        }

        // Remote control: qs ipc call bar closePopups | toggleControl
        IpcHandler {
            target: "bar"

            function closePopups(): void {
                bar.closePopups();
            }
            function toggleControl(): void {
                bar.toggleControl();
            }
            function panelStep(dir: int): void {
                controlPanelPopup.stepVertical(dir);
            }
            function panelActivate(): void {
                controlPanelPopup.activateSelected();
            }
        }

        property int cpuUsage: 0
        property real memUsed: 0

        property real cpuTotal: 0
        property real cpuIdle: 0

        Timer {
            id: perfTimer

            interval: 2000
            running: true
            repeat: true
            triggeredOnStart: true

            onTriggered: {
                cpuProbe.running = true;
                memProbe.running = true;
            }
        }

        Process {
            id: cpuProbe

            command: ["sh", "-c", "grep '^cpu ' /proc/stat"]

            stdout: StdioCollector {
                onStreamFinished: {
                    const nums = text.trim().split(/\s+/);

                    // Bad reads must not poison the totals (NaN sticks).
                    if (nums.length < 6 || nums[0] !== "cpu")
                        return;
                    let total = 0;

                    for (let i = 1; i < nums.length; i++) {
                        const v = parseInt(nums[i]);

                        if (isNaN(v))
                            return;
                        total += v;
                    }

                    const idleUser = parseInt(nums[4]);
                    const idleNice = parseInt(nums[5]);

                    if (isNaN(idleUser) || isNaN(idleNice))
                        return;
                    const idle = idleUser + idleNice;

                    if (bar.cpuTotal > 0) {
                        const dTotal = total - bar.cpuTotal;
                        const dIdle = idle - bar.cpuIdle;

                        if (dTotal > 0)
                            bar.cpuUsage = Math.round((dTotal - dIdle) / dTotal * 100);
                    }

                    bar.cpuTotal = total;
                    bar.cpuIdle = idle;
                }
            }
        }

        Process {
            id: memProbe

            command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]

            stdout: StdioCollector {
                onStreamFinished: {
                    const totalMatch = text.match(/MemTotal:\s+(\d+)/);
                    const availMatch = text.match(/MemAvailable:\s+(\d+)/);

                    if (totalMatch && availMatch) {
                        const totalKb = parseInt(totalMatch[1]);
                        const availKb = parseInt(availMatch[1]);

                        if (isNaN(totalKb) || isNaN(availKb))
                            return;
                        bar.memUsed = (totalKb - availKb) / 1024 / 1024;
                    }
                }
            }
        }

        property var wifiDevice: {
            const devices = Networking.devices.values;

            return devices.find(device => device.type === DeviceType.Wifi) ?? null;
        }

        // One-shot startup check: helpers we shell out to. Missing
        // ones fail silently elsewhere, so toast them once here.
        Process {
            id: depCheck

            command: ["sh", "-c", "for b in cliphist wl-copy hyprctl jq brightnessctl notify-send; do command -v \"$b\" >/dev/null || printf '%s\\n' \"$b\"; done"]

            stdout: StdioCollector {
                onStreamFinished: {
                    const missing = text.trim().split("\n").filter(s => s !== "");

                    if (missing.length === 0)
                        return;

                    // No notify-send, no toast path; don't bother.
                    if (missing.includes("notify-send"))
                        return;
                    Quickshell.execDetached(["notify-send", "-a", "quickshell", "-t", "8000", "-i", "dialog-warning-symbolic", "Missing helper binaries", missing.join(", ")]);
                }
            }

            Component.onCompleted: depCheck.running = true
        }

        property var connectedWifi: {
            if (!wifiDevice)
                return null;

            return wifiDevice.networks.values.find(network => network.connected) ?? null;
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
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }

            spacing: 12

            Tray {}
            SystemGroup {
                id: systemGroup

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
            volumeControl: systemGroup.volumeControl
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

        PasswordDialog {
            id: passwordDialog
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

        GlobalShortcut {
            appid: "qs-bar"
            name: "Toggle Power Menu"
            description: "Open the power menu"
            onPressed: bar.togglePower()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Toggle Control Panel"
            description: "Open the control panel"
            onPressed: bar.toggleControl()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Toggle Launcher"
            description: "Open the application launcher"
            onPressed: bar.toggleLauncher()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Toggle Clipboard"
            description: "Open the clipboard history picker"
            onPressed: bar.toggleClipboard()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Toggle Caffeine"
            description: "Toggle caffeine mode (block idle)"
            onPressed: Services.Modes.toggleCaffeine()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Toggle DND"
            description: "Toggle do-not-disturb mode"
            onPressed: Services.Modes.toggleDnd()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Volume Up"
            description: "Raise the volume"
            onPressed: Services.Media.volumeUp()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Volume Down"
            description: "Lower the volume"
            onPressed: Services.Media.volumeDown()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Volume Mute"
            description: "Mute the volume"
            onPressed: Services.Media.toggleVolumeMute()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Mic Mute"
            description: "Mute the microphone"
            onPressed: Services.Media.toggleMicMute()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Media Play/Pause"
            description: "Play or pause media"
            onPressed: Services.Media.mediaToggle()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Media Next"
            description: "Next media track"
            onPressed: Services.Media.mediaNext()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Media Previous"
            description: "Previous media track"
            onPressed: Services.Media.mediaPrev()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Brightness Up"
            description: "Raise the brightness"
            onPressed: Services.Media.brightnessUp()
        }

        GlobalShortcut {
            appid: "qs-bar"
            name: "Brightness Down"
            description: "Lower the brightness"
            onPressed: Services.Media.brightnessDown()
        }
    }

    PanelWindow {
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusiveZone: -1

        color: "transparent"

        WlrLayershell.namespace: "wallpaper"
        WlrLayershell.layer: WlrLayer.Background

        Image {
            anchors.fill: parent

            source: "file://" + Quickshell.env("HOME") + "/dotfiles/wallpapers/wallpaper.jpg"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
    }

    // PanelWindows cannot nest inside the bar: keep this top-level.
    ToastStack {
        id: toastStack
    }
}
