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

        WlrLayershell.namespace: "qs-bar"

        function openExclusive(target): void {
            const open = !target.visible

            calendarPopup.visible = false
            controlPanelPopup.visible = false
            wifiPopup.visible = false
            bluetoothPopup.visible = false
            powerPopup.visible = false
            passwordDialog.visible = false

            target.visible = open
        }

        function toggleCalendar(): void { openExclusive(calendarPopup) }
        function toggleControl(): void { openExclusive(controlPanelPopup) }
        function toggleWifi(): void { openExclusive(wifiPopup) }
        function toggleBluetooth(): void { openExclusive(bluetoothPopup) }
        function togglePower(): void { openExclusive(powerPopup) }

        // Bottom edge of the open right-side popup in TOAST-margin
        // space, 0 when none is open. At most one popup is visible
        // via openExclusive; the toast stack parks below it and
        // never hides behind it.
        property int rightPopupBottom: {
            const top = Palette.popupTopGap
            const popups = [
                controlPanelPopup,
                wifiPopup, bluetoothPopup, powerPopup
            ]
            let bottom = 0

            for (const p of popups) {
                if (p.visible)
                    bottom = Math.max(bottom, top + p.height)
            }

            return bottom
        }

        function closePopups(): void {
            calendarPopup.visible = false
            controlPanelPopup.visible = false
            wifiPopup.visible = false
            bluetoothPopup.visible = false
            powerPopup.visible = false
            passwordDialog.visible = false
        }

        function showPasswordDialog(network): void {
            // The dialog grabs keyboard focus, so it must own it alone:
            // a second grabber underneath steals typed passwords.
            wifiPopup.visible = false
            passwordDialog.network = network
            passwordDialog.visible = true
        }

        function closePasswordAndControl(): void {
            passwordDialog.visible = false
            controlPanelPopup.visible = false
        }

        // Shared grab for the control panel (history cards live in
        // the same window, so there is exactly one focus target) plus
        // the toast stack (clicks on toasts must not clear the grab).
        // (Same deferred-activation rule as elsewhere: asserting
        // active in the show frame leaves the grab dead.)
        HyprlandFocusGrab {
            id: panelGrab

            windows: [controlPanelPopup, historyPanel, toastStack]

            // A clear also fires when these windows hide for other
            // reasons (e.g. opening wifi from a panel tile hides the
            // panel first): close ONLY our own windows, never the
            // newly opened popup. Equivalent for real outside clicks,
            // since exclusivity leaves nothing else open.
            onCleared: controlPanelPopup.visible = false
        }

        Timer {
            interval: 100
            running: controlPanelPopup.visible
            repeat: false

            onTriggered: panelGrab.active = true
        }

        function revealHistory(i: int): void {
            historyPanel.revealAt(i)
        }

        // Remote control (debugging): qs
        // ipc call bar closePopups | toggleControl | panelStep -1
        IpcHandler {
            target: "bar"

            function closePopups(): void { bar.closePopups() }
            function toggleControl(): void { bar.toggleControl() }
            function panelStep(dir: int): void {
                controlPanelPopup.stepVertical(dir)
            }
            function panelActivate(): void {
                controlPanelPopup.activateSelected()
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
                cpuProbe.running = true
                memProbe.running = true
            }
        }

        Process {
            id: cpuProbe

            command: [
                "sh",
                "-c",
                "grep '^cpu ' /proc/stat"
            ]

            stdout: StdioCollector {
                onStreamFinished: {
                    const nums = text.trim().split(/\s+/)

                    let total = 0

                    for (let i = 1; i < nums.length; i++)
                        total += parseInt(nums[i])

                    const idle =
                        parseInt(nums[4]) + parseInt(nums[5])

                    if (bar.cpuTotal > 0) {
                        const dTotal = total - bar.cpuTotal
                        const dIdle = idle - bar.cpuIdle

                        if (dTotal > 0)
                            bar.cpuUsage =
                                Math.round((dTotal - dIdle) / dTotal * 100)
                    }

                    bar.cpuTotal = total
                    bar.cpuIdle = idle
                }
            }
        }

        Process {
            id: memProbe

            command: [
                "sh",
                "-c",
                "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"
            ]

            stdout: StdioCollector {
                onStreamFinished: {
                    const totalMatch =
                        text.match(/MemTotal:\s+(\d+)/)
                    const availMatch =
                        text.match(/MemAvailable:\s+(\d+)/)

                    if (totalMatch && availMatch) {
                        bar.memUsed = (
                            parseInt(totalMatch[1]) -
                            parseInt(availMatch[1])
                        ) / 1024 / 1024
                    }
                }
            }
        }

        property var wifiDevice: {
            const devices = Networking.devices.values

            return devices.find(
                device => device.type === DeviceType.Wifi
            ) ?? null
        }

        property var connectedWifi: {
            if (!wifiDevice)
                return null

            return wifiDevice.networks.values.find(
                network => network.connected
            ) ?? null
        }

        // ========================================================
        // LEFT: WORKSPACES
        // ========================================================

        Workspaces {}

        // ========================================================
        // CLOCK
        // ========================================================

        SystemClock {
            id: systemClock

            precision: SystemClock.Minutes
        }

        Clock {
            bar: bar
            clockSource: systemClock
        }

        // ========================================================
        // RIGHT SIDE
        // ========================================================

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
            BellIcon { bar: bar }
            PowerIcon { bar: bar }
        }

        // ========================================================
        // POPUPS
        // ========================================================

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

    // Top-level window: PanelWindows cannot nest inside the bar.
    ToastStack {
        id: toastStack
    }
}