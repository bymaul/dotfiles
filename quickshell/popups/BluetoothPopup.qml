import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../Palette.js" as Palette

BasePopup {
    id: bluetoothPopup

    implicitWidth: Palette.popupWidth
    implicitHeight: 430

    Shortcut {
        sequence: "Escape"
        onActivated: bar.closePopups()
    }

    onVisibleChanged: {
        if (visible)
            btList.currentIndex = 0;
    }

    function stepSelection(dir: int): void {
        if (btList.count === 0)
            return;
        btList.currentIndex = Math.max(0, Math.min(btList.count - 1, btList.currentIndex + dir));
        btList.positionViewAtIndex(btList.currentIndex, ListView.Contain);
    }

    function selectedDevice(): var {
        const devs = Bluetooth.defaultAdapter?.devices.values ?? [];

        if (btList.currentIndex < 0 || btList.currentIndex >= devs.length)
            return null;

        return devs[btList.currentIndex];
    }

    function activateDevice(device): void {
        if (!device || device.pairing)
            return;
        if (device.connected) {
            device.disconnect();
            return;
        }

        if (device.paired) {
            device.connect();
            return;
        }

        device.pair();
    }

    function toggleAdapter(): void {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
    }

    // Manual discovery auto-stops after 15s (battery).
    function toggleScan(): void {
        if (!Bluetooth.defaultAdapter)
            return;
        Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering;

        if (Bluetooth.defaultAdapter.discovering)
            scanTimeout.restart();
        else
            scanTimeout.stop();
    }

    Timer {
        id: scanTimeout

        interval: 15000
        repeat: false

        onTriggered: {
            if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.discovering = false;
        }
    }

    function forgetSelected(): void {
        const dev = bluetoothPopup.selectedDevice();

        if (dev && dev.paired && !dev.connected)
            dev.forget();
    }

    function toggleTrust(): void {
        const dev = bluetoothPopup.selectedDevice();

        if (dev)
            dev.trusted = !dev.trusted;
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
    Shortcut {
        sequence: "s"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.toggleScan()
    }
    Shortcut {
        sequence: "d"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.forgetSelected()
    }
    Shortcut {
        sequence: "Delete"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.forgetSelected()
    }
    Shortcut {
        sequence: "t"
        enabled: bluetoothPopup.visible
        onActivated: bluetoothPopup.toggleTrust()
    }

    Rectangle {
        anchors.fill: parent

        radius: 0

        color: Palette.bg

        border.width: 0

        Column {
            anchors {
                fill: parent
                margins: Palette.popupPadding
            }

            spacing: Palette.popupSpacing

            Row {
                width: parent.width
                height: Palette.rowHeight
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: parent.height

                    radius: 0

                    color: enableHover.containsMouse ? Palette.hoverBg : Palette.surface
                    border.width: 0

                    Text {
                        anchors.centerIn: parent

                        text: Bluetooth.defaultAdapter?.enabled ? "󰂲  Disable" : "󰂯  Enable"

                        color: Bluetooth.defaultAdapter?.enabled ? Palette.dim : Palette.accent

                        font.family: Palette.font
                        font.pixelSize: Palette.px12
                    }

                    MouseArea {
                        id: enableHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            bluetoothPopup.toggleAdapter();
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: parent.height

                    radius: 0

                    color: scanHover.containsMouse ? Palette.hoverBg : Palette.surface
                    border.width: 0

                    Text {
                        anchors.centerIn: parent

                        text: Bluetooth.defaultAdapter?.discovering ? "󰑓  Scanning..." : "󰑐  Scan"

                        color: Palette.dim

                        font.family: Palette.font
                        font.pixelSize: Palette.px12
                    }

                    MouseArea {
                        id: scanHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            bluetoothPopup.toggleScan();
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: parent.height - 36 - 14 - 16

                ListView {
                    id: btList

                    anchors.fill: parent

                    clip: true

                    model: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices : null

                    spacing: 4

                    onCountChanged: {
                        if (currentIndex >= count)
                            currentIndex = Math.max(0, count - 1);
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        readonly property bool selected: btList.currentIndex === index
                        readonly property bool connected: modelData.state === BluetoothDeviceState.Connected

                        width: btList.width
                        height: Palette.listRowHeight

                        radius: 0

                        color: selected ? Palette.accent : btRowHover.containsMouse ? Palette.hoverBg : (connected ? Palette.activeBg : "transparent")
                        border.width: selected ? 1 : 0
                        border.color: selected ? Palette.accent : connected ? Palette.accent : Palette.dim

                        Row {
                            anchors {
                                fill: parent
                                leftMargin: 8
                                rightMargin: 8
                            }

                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter

                                width: 18

                                text: modelData.connected ? "󰂯" : "󰂲"

                                color: selected ? Palette.onAccent : modelData.connected ? Palette.accent : btRowHover.containsMouse ? Palette.fg : Palette.dim

                                font.family: Palette.font

                                font.pixelSize: Palette.px13
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter

                                width: parent.width - 58

                                spacing: 2

                                Text {
                                    width: parent.width

                                    text: modelData.name || "Unknown device"

                                    color: selected ? Palette.onAccent : (modelData.connected || btRowHover.containsMouse) ? Palette.fg : Palette.dim

                                    font.family: Palette.font

                                    font.pixelSize: Palette.px12

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width

                                    text: {
                                        let s;

                                        if (modelData.state === BluetoothDeviceState.Connected)
                                            s = "Connected";
                                        else if (modelData.state === BluetoothDeviceState.Connecting)
                                            s = "Connecting...";
                                        else if (modelData.state === BluetoothDeviceState.Disconnecting)
                                            s = "Disconnecting...";
                                        else if (modelData.pairing)
                                            s = "Pairing...";
                                        else
                                            s = "Available";

                                        if (modelData.trusted && !modelData.connected)
                                            s += " · Trusted";

                                        if (modelData.address !== "")
                                            s += " · " + modelData.address;

                                        return s;
                                    }

                                    color: selected ? Palette.onAccent : btRowHover.containsMouse ? Palette.fg : Palette.dim

                                    font.family: Palette.font

                                    font.pixelSize: Palette.px10
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter

                                width: 24

                                horizontalAlignment: Text.AlignHCenter

                                text: "󰅖"

                                color: selected ? Palette.onAccent : forgetHover.containsMouse ? Palette.fg : Palette.dim

                                font.family: Palette.font

                                font.pixelSize: Palette.px13

                                visible: modelData.paired && !modelData.connected

                                MouseArea {
                                    id: forgetHover

                                    anchors.fill: parent

                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: modelData.forget()
                                }
                            }
                        }

                        MouseArea {
                            id: btRowHover

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                bluetoothPopup.activateDevice(modelData);
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent

                    visible: !(Bluetooth.defaultAdapter?.enabled ?? true)

                    text: "󰂲  Bluetooth is off"

                    color: Palette.dim

                    font.family: Palette.font

                    font.pixelSize: Palette.px12
                }
            }

            Text {
                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                text: "↵ connect · d forget · t trust · s scan · e on/off"

                wrapMode: Text.WordWrap

                color: Palette.dim

                font.family: Palette.font
                font.pixelSize: Palette.px10
            }
        }
    }
}
