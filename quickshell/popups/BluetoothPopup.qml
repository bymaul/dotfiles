import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Bluetooth
import "../Palette.js" as Palette

PopupWindow {
    id: bluetoothPopup

    required property var bar

    anchor.window: bar

    anchor.rect.x: bar.width - width - Palette.popupMargin
    anchor.rect.y: bar.height + Palette.popupTopGap

    implicitWidth: Palette.popupWidth
    implicitHeight: 430

    visible: false

    color: "transparent"

    HyprlandFocusGrab {
        id: bluetoothGrab

        windows: [bluetoothPopup]

        // No grabFocus: it dismisses on any grab break (e.g. toast
        // expiry). Assert active from the timer, not bound to visible.
        onCleared: bluetoothPopup.visible = false
    }

    Timer {
        interval: 100
        running: bluetoothPopup.visible
        repeat: false

        onTriggered: bluetoothGrab.active = true
    }

    Shortcut {
        sequence: "Escape"
        onActivated: bar.closePopups()
    }

    onVisibleChanged: {
        if (visible)
            btList.currentIndex = 0
    }

    function stepSelection(dir: int): void {
        if (btList.count === 0)
            return

        btList.currentIndex = Math.max(0,
            Math.min(btList.count - 1, btList.currentIndex + dir))
        btList.positionViewAtIndex(btList.currentIndex, ListView.Contain)
    }

    function selectedDevice(): var {
        const devs = Bluetooth.defaultAdapter?.devices.values ?? []

        if (btList.currentIndex < 0 || btList.currentIndex >= devs.length)
            return null

        return devs[btList.currentIndex]
    }

    function activateDevice(device): void {
        if (!device || device.pairing)
            return

        if (device.connected) {
            device.disconnect()
            return
        }

        if (device.paired) {
            device.connect()
            return
        }

        device.pair()
    }

    function toggleAdapter(): void {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled =
                !Bluetooth.defaultAdapter.enabled
    }

    // Letter shortcuts stay scoped to the open popup so they never
    // leak into typing elsewhere.
    Shortcut {
        sequence: "Down"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.stepSelection(1)
    }
    Shortcut {
        sequence: "Up"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.stepSelection(-1)
    }
    Shortcut {
        sequence: "j"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.stepSelection(1)
    }
    Shortcut {
        sequence: "k"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.stepSelection(-1)
    }
    Shortcut {
        sequence: "Return"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.activateDevice(bluetoothPopup.selectedDevice())
    }
    Shortcut {
        sequence: "Enter"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.activateDevice(bluetoothPopup.selectedDevice())
    }
    Shortcut {
        sequence: "e"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.toggleAdapter()
    }

    Rectangle {
        anchors.fill: parent

        radius: 0

        color: Palette.bg

        border.width: 1
        border.color: Palette.border

        Column {
            anchors {
                fill: parent
                margins: 12
            }

            spacing: 8

            // ADAPTER TOGGLE
            Rectangle {
                width: parent.width
                height: 36

                radius: 0

                color: btToggleHover.containsMouse
                    ? Palette.surfaceHover : Palette.surface

                Text {
                    anchors.centerIn: parent

                    text: Bluetooth.defaultAdapter?.enabled
                        ? "󰂲  Disable"
                        : "󰂯  Enable"

                    color: Bluetooth.defaultAdapter?.enabled
                        ? Palette.fg
                        : Palette.accent

                    font.family:
                        Palette.font

                    font.pixelSize: Palette.px13
                }

                MouseArea {
                    id: btToggleHover

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            bluetoothPopup.toggleAdapter()
                        }
                }
            }

            // DEVICE LIST + ADAPTER OFF HINT
            Item {
                width: parent.width
                height: parent.height - 36 - 18 - 16

                ListView {
                    id: btList

                    anchors.fill: parent

                    clip: true

                    model: Bluetooth.defaultAdapter
                        ? Bluetooth.defaultAdapter.devices
                        : null

                    spacing: 4

                    onCountChanged: {
                        if (currentIndex >= count)
                            currentIndex = Math.max(0, count - 1)
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        // Keyboard selection outshines hover:
                        // surfaceHover (connectedRow when connected)
                        // vs plain surface.
                        readonly property bool selected:
                            btList.currentIndex === index

                        width: btList.width
                        height: 40

                        radius: 0

                        color: {
                            if (selected)
                                return modelData.state ===
                                    BluetoothDeviceState.Connected
                                    ? Palette.connectedRow
                                    : Palette.surfaceHover

                            if (btRowHover.containsMouse)
                                return Palette.surface

                            return modelData.state ===
                                BluetoothDeviceState.Connected
                                ? Palette.surface
                                : "transparent"
                        }

                        Row {
                            anchors {
                                fill: parent
                                leftMargin: 8
                                rightMargin: 8
                            }

                            spacing: 8

                            Text {
                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: modelData.connected
                                    ? "󰂯"
                                    : "󰂲"

                                color: modelData.connected
                                    ? Palette.accent
                                    : Palette.dim

                                font.family:
                                    Palette.font

                                font.pixelSize: Palette.px16
                            }

                            Column {
                                anchors.verticalCenter:
                                    parent.verticalCenter

                                width: parent.width - 30

                                spacing: 2

                                Text {
                                    width: parent.width

                                    text: modelData.name ||
                                        "Unknown device"

                                    color: modelData.connected
                                        ? Palette.fg
                                        : Palette.dim

                                    font.family:
                                        Palette.font

                                    font.pixelSize: Palette.px13

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width

                                    text: {
                                        if (modelData.state ===
                                                BluetoothDeviceState.Connected)
                                            return "Connected"
                                        if (modelData.state ===
                                                BluetoothDeviceState.Connecting)
                                            return "Connecting..."
                                        if (modelData.state ===
                                                BluetoothDeviceState.Disconnecting)
                                            return "Disconnecting..."
                                        if (modelData.pairing)
                                            return "Pairing..."
                                        return "Available"
                                    }

                                    color: Palette.dim

                                    font.family:
                                        Palette.font

                                    font.pixelSize: Palette.px10
                                }
                            }
                        }

                        MouseArea {
                            id: btRowHover

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                bluetoothPopup.activateDevice(modelData)
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent

                    visible: !(Bluetooth.defaultAdapter?.enabled
                        ?? true)

                    text: "󰂲  Bluetooth is off"

                    color: Palette.dim

                    font.family:
                        Palette.font

                    font.pixelSize: Palette.px12
                }
            }

            // KEYBOARD HINTS
            Text {
                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                text: "j/k move · enter connect · e on/off"

                color: Palette.dim

                font.family: Palette.font
                font.pixelSize: Palette.px10
            }
        }
    }
}