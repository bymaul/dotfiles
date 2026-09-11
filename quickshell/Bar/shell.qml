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

        property int cpuUsage: 0
        property real memUsed: 0
        property real brightness: 0
        property bool brightnessAvailable: true

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

                if (bar.brightnessAvailable)
                    brightnessProbe.running = true
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

        Process {
            id: brightnessProbe

            // Routed through sh so a missing brightnessctl binary still
            // yields a reliable nonzero exit (QProcess start failures
            // don't guarantee onExited).
            command: [
                "sh",
                "-c",
                "command -v brightnessctl >/dev/null && brightnessctl -m || exit 1"
            ]

            stdout: StdioCollector {
                onStreamFinished: {
                    const fields = text.split(",")

                    if (fields.length >= 4)
                        bar.brightness = parseFloat(fields[3]) || 0
                    else
                        bar.brightnessAvailable = false
                }
            }

            // No backlight (desktop): hide the slider instead of
            // parking it at a dead 0% forever.
            onExited: exitCode => {
                if (exitCode !== 0)
                    bar.brightnessAvailable = false
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
    }
}