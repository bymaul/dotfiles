import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../components"
import "../Palette.js" as Palette
BasePopup {
    id: root
    implicitWidth: Palette.popupWidth
    implicitHeight: 36 + Palette.listHeight(Palette.listVisible) + Palette.popupSpacing * 3 + 16 + hint.implicitHeight
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }
    Shortcut {
        sequence: "q"
        enabled: root.visible
        onActivated: root.close()
    }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Down"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Up"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Left"; enabled: root.visible; onActivated: root.moveHeader(-1) }
    Shortcut { sequence: "Right"; enabled: root.visible; onActivated: root.moveHeader(1) }
    Shortcut { sequence: "Tab"; enabled: root.visible; onActivated: root.focusNext() }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible; onActivated: root.focusPrev() }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "e"; enabled: root.visible; onActivated: root.toggleAdapter() }
    Shortcut { sequence: "s"; enabled: root.visible; onActivated: root.toggleScan() }
    Shortcut { sequence: "d"; enabled: root.visible; onActivated: root.forgetSelected() }
    Shortcut { sequence: "Delete"; enabled: root.visible; onActivated: root.forgetSelected() }
    Shortcut { sequence: "t"; enabled: root.visible; onActivated: root.toggleTrust() }
    property int headIndex: -1
    onVisibleChanged: {
        if (visible) {
            headIndex = -1;
            btList.currentIndex = 0;
        }
    }
    function stepSelection(dir: int): void {
        headIndex = -1;
        if (btList.count === 0)
            return;
        btList.currentIndex = Palette.clamp(btList.currentIndex + dir, 0, btList.count - 1);
        btList.positionViewAtIndex(btList.currentIndex, ListView.Contain);
    }
    function selectRow(i: int): void {
        headIndex = -1;
        btList.currentIndex = Palette.clamp(i, 0, Math.max(0, btList.count - 1));
        btList.positionViewAtIndex(btList.currentIndex, ListView.Contain);
    }
    function moveHeader(dir: int): void {
        if (headIndex < 0)
            return;
        headIndex = Palette.clamp(headIndex + dir, 0, 1);
    }
    function focusNext(): void {
        headIndex = headIndex >= 1 ? -1 : headIndex + 1;
    }
    function focusPrev(): void {
        headIndex = headIndex <= -1 ? 1 : headIndex - 1;
    }
    function activateSelected(): void {
        if (headIndex === 0) {
            root.toggleAdapter();
            return;
        }
        if (headIndex === 1) {
            root.toggleScan();
            return;
        }
        root.activateDevice(root.selectedDevice());
    }
    function selectedDevice(): var {
        const devs = Bluetooth.defaultAdapter?.devices.values ?? [];
        if (btList.currentIndex < 0 || btList.currentIndex >= devs.length)
            return null;
        return devs[btList.currentIndex];
    }
    function activateDevice(device: var): void {
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
        interval: Palette.scanTimeout
        repeat: false
        onTriggered: {
            if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.discovering = false;
        }
    }
    function forgetSelected(): void {
        const dev = root.selectedDevice();
        if (dev && dev.paired && !dev.connected)
            dev.forget();
    }
    function toggleTrust(): void {
        const dev = root.selectedDevice();
        if (dev)
            dev.trusted = !dev.trusted;
    }
    function statusText(dev: var): string {
        let s = "Available";
        if (dev.state === BluetoothDeviceState.Connected)
            s = "Connected";
        else if (dev.state === BluetoothDeviceState.Connecting)
            s = "Connecting...";
        else if (dev.state === BluetoothDeviceState.Disconnecting)
            s = "Disconnecting...";
        else if (dev.pairing)
            s = "Pairing...";
        if (dev.trusted && !dev.connected)
            s += " · Trusted";
        if (dev.address !== "")
            s += " · " + dev.address;
        return s;
    }
    PopupCard {
        Row {
            width: parent.width
            height: Palette.rowHeight
            spacing: Palette.popupSpacing
            PopupButton {
                label: Bluetooth.defaultAdapter?.enabled ? "󰂲  Disable" : "󰂯  Enable"
                selected: root.headIndex === 0
                onHovered: root.headIndex = 0
                onClicked: root.toggleAdapter()
            }
            PopupButton {
                label: Bluetooth.defaultAdapter?.discovering ? "󰑓  Scanning..." : "󰑐  Scan"
                selected: root.headIndex === 1
                onHovered: root.headIndex = 1
                onClicked: root.toggleScan()
            }
        }
        Item {
            width: parent.width
            height: Palette.listHeight(Palette.listVisible)
            ListView {
                id: btList
                anchors.fill: parent
                clip: true
                model: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices : null
                spacing: Palette.listSpacing
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
                    color: selected ? Palette.activeBg : rowArea.containsMouse ? Palette.hoverBg : (connected ? Palette.activeBg : "transparent")
                    border.width: (!selected && connected) ? 1 : 0
                    border.color: Palette.accent
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.selectRow(index);
                        }
                        onClicked: root.activateDevice(modelData)
                    }
                    Row {
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: Palette.popupSpacing
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            text: modelData.connected ? "󰂯" : "󰂲"
                            color: selected ? Palette.fg : modelData.connected ? Palette.accent : rowArea.containsMouse ? Palette.fg : Palette.dim
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
                                color: selected ? Palette.fg : (modelData.connected || rowArea.containsMouse) ? Palette.fg : Palette.dim
                                font.family: Palette.font
                                font.pixelSize: Palette.px12
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: root.statusText(modelData)
                                color: selected ? Palette.fg : rowArea.containsMouse ? Palette.fg : Palette.dim
                                font.family: Palette.font
                                font.pixelSize: Palette.px10
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            horizontalAlignment: Text.AlignHCenter
                            text: "󰅖"
                            color: selected ? Palette.fg : forgetArea.containsMouse ? Palette.fg : Palette.dim
                            font.family: Palette.font
                            font.pixelSize: Palette.px13
                            visible: modelData.paired && !modelData.connected
                            MouseArea {
                                id: forgetArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    mouse.accepted = true;
                                    root.forgetSelected();
                                }
                            }
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
        HintText {
            id: hint
            text: "jk move · Tab header · ↵ connect · d forget · t trust · s scan · e on/off"
        }
    }
}
