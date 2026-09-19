import QtQuick
import Quickshell
import Quickshell.Networking
import "../components"
import "../Palette.js" as Palette
BasePopup {
    id: root
    implicitWidth: Palette.popupWidth
    implicitHeight: (root.authTarget === null ? wifiList.height : authCol.height) + 36 + 36 + Palette.popupSpacing * 3 + 16 + hint.implicitHeight
    Shortcut { sequence: "j"; enabled: root.visible && root.authTarget === null; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible && root.authTarget === null; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Down"; enabled: root.visible && root.authTarget === null; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Up"; enabled: root.visible && root.authTarget === null; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Left"; enabled: root.visible && root.authTarget === null; onActivated: root.moveHeader(-1) }
    Shortcut { sequence: "Right"; enabled: root.visible && root.authTarget === null; onActivated: root.moveHeader(1) }
    Shortcut { sequence: "Tab"; enabled: root.visible && root.authTarget === null; onActivated: root.focusNext() }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible && root.authTarget === null; onActivated: root.focusPrev() }
    Shortcut { sequence: "Return"; enabled: root.visible && root.authTarget === null; onActivated: root.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: root.visible && root.authTarget === null; onActivated: root.activateSelected() }
    Shortcut { sequence: "Space"; enabled: root.visible && root.authTarget === null; onActivated: root.activateSelected() }
    Shortcut { sequence: "d"; enabled: root.visible && root.authTarget === null; onActivated: root.forgetSelected() }
    Shortcut { sequence: "Delete"; enabled: root.visible && root.authTarget === null; onActivated: root.forgetSelected() }
    Shortcut { sequence: "s"; enabled: root.visible && root.authTarget === null; onActivated: root.toggleScan() }
    Shortcut { sequence: "e"; enabled: root.visible && root.authTarget === null; onActivated: root.toggleWifiEnabled() }
    Shortcut { sequence: "h"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = 0 }
    Shortcut { sequence: "l"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = 1 }
    Shortcut { sequence: "Left"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = 0 }
    Shortcut { sequence: "Right"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = 1 }
    Shortcut { sequence: "Tab"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = (root.selectedButton + 1) % 2 }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = (root.selectedButton + 1) % 2 }
    Shortcut { sequence: "Space"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.activateSelectedButton() }
    Shortcut { sequence: "Return"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.activateSelectedButton() }
    Shortcut { sequence: "Enter"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.activateSelectedButton() }
    property int headIndex: -1
    property var authTarget: null
    property string authError: ""
    property var pendingNetwork: null
    property int selectedButton: 1
    function cancelOrClose(): void {
        if (root.authTarget)
            root.cancelAuth();
        else
            root.close();
    }
    onVisibleChanged: {
        if (visible) {
            headIndex = -1;
            wifiList.currentIndex = 0;
        } else {
            root.cancelAuth();
        }
    }
    function stepSelection(dir: int): void {
        headIndex = -1;
        if (wifiList.count === 0)
            return;
        wifiList.currentIndex = Palette.clamp(wifiList.currentIndex + dir, 0, wifiList.count - 1);
        wifiList.positionViewAtIndex(wifiList.currentIndex, ListView.Contain);
    }
    function selectRow(i: int): void {
        headIndex = -1;
        wifiList.currentIndex = Palette.clamp(i, 0, Math.max(0, wifiList.count - 1));
        wifiList.positionViewAtIndex(wifiList.currentIndex, ListView.Contain);
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
            root.toggleWifiEnabled();
            return;
        }
        if (headIndex === 1) {
            root.toggleScan();
            return;
        }
        root.activateNetwork(root.selectedNetwork());
    }
    function selectedNetwork(): var {
        const nets = bar.wifiDevice?.networks?.values ?? [];
        if (wifiList.currentIndex < 0 || wifiList.currentIndex >= nets.length)
            return null;
        return nets[wifiList.currentIndex];
    }
    function activateNetwork(network: var): void {
        if (!network)
            return;
        if (network.connected) {
            network.disconnect();
            return;
        }
        if (network.known) {
            network.connect();
            return;
        }
        root.enterAuth(network);
    }
    function enterAuth(network: var): void {
        root.authTarget = network;
        root.authError = "";
        root.pendingNetwork = null;
        root.selectedButton = 1;
        root.focusTarget = field;
        field.forceActiveFocus();
    }
    function cancelAuth(): void {
        root.authTarget = null;
        root.authError = "";
        root.pendingNetwork = null;
        field.text = "";
        field.focus = false;
        root.focusTarget = null;
    }
    function activateSelectedButton(): void {
        if (root.selectedButton === 0)
            root.cancelAuth();
        else
            root.doConnect();
    }
    function resolveAuthNetwork(): var {
        const name = root.authTarget?.name;
        if (!name || !bar.wifiDevice?.networks)
            return root.authTarget;
        return (bar.wifiDevice.networks.values ?? []).find(n => n && n.name === name) ?? root.authTarget;
    }
    function doConnect(): void {
        if (root.pendingNetwork)
            return;
        const net = root.resolveAuthNetwork();
        if (!net)
            return;
        root.authError = "Connecting...";
        root.pendingNetwork = net;
        net.connectWithPsk(field.text);
        field.text = "";
        field.forceActiveFocus();
    }
    Connections {
        target: root.pendingNetwork
        enabled: root.pendingNetwork !== null
        function onConnectedChanged() {
            if (root.pendingNetwork?.connected) {
                root.pendingNetwork = null;
                bar.closePopups();
            }
        }
        function onConnectionFailed(reason) {
            const net = root.pendingNetwork;
            root.pendingNetwork = null;
            root.authTarget = net;
            root.authError = (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout) ? "Wrong password, try again" : "Connection failed (" + ConnectionFailReason.toString(reason) + ")";
            root.focusTarget = field;
            field.forceActiveFocus();
        }
    }
    function forgetSelected(): void {
        const net = root.selectedNetwork();
        if (net && net.known && !net.connected)
            net.forget();
    }
    function toggleScan(): void {
        if (!bar.wifiDevice)
            return;
        bar.wifiDevice.scannerEnabled = !bar.wifiDevice.scannerEnabled;
        if (bar.wifiDevice.scannerEnabled)
            scanTimeout.restart();
        else
            scanTimeout.stop();
    }
    Timer {
        id: scanTimeout
        interval: Palette.scanTimeout
        repeat: false
        onTriggered: {
            if (bar.wifiDevice)
                bar.wifiDevice.scannerEnabled = false;
        }
    }
    function toggleWifiEnabled(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }
    PopupCard {
        Rectangle {
            width: parent.width
            height: Palette.rowHeight
            color: "transparent"
            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                }
                width: parent.width - 20
                text: bar.connectedWifi ? "󰤨 " + bar.connectedWifi.name : (bar.wifiDevice?.networks?.values ?? []).find(n => n && n.state === ConnectionState.Connecting) ? "󰤭 Connecting..." : Networking.wifiEnabled ? "󰤭 Not connected" : "󰤯 Wi-Fi off"
                color: bar.connectedWifi ? Palette.fg : Palette.dim
                font.family: Palette.font
                font.pixelSize: Palette.px12
                elide: Text.ElideRight
            }
        }
        Row {
            width: parent.width
            height: Palette.rowHeight
            spacing: Palette.popupSpacing
            PopupButton {
                label: Networking.wifiEnabled ? "󰖪  Disable" : "󰖩  Enable"
                selected: root.headIndex === 0
                onHovered: root.headIndex = 0
                onClicked: root.toggleWifiEnabled()
            }
            PopupButton {
                label: bar.wifiDevice?.scannerEnabled ? "󰑓  Scanning..." : "󰑐  Scan"
                selected: root.headIndex === 1
                onHovered: root.headIndex = 1
                onClicked: root.toggleScan()
            }
        }
        ListView {
            id: wifiList
            visible: root.authTarget === null
            width: parent.width
            height: Palette.listHeight(Palette.listVisible)
            clip: true
            model: bar.wifiDevice?.networks ?? null
            spacing: Palette.listSpacing
            onCountChanged: {
                if (currentIndex >= count)
                    currentIndex = Math.max(0, count - 1);
            }
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool selected: wifiList.currentIndex === index
                width: wifiList.width
                height: Palette.listRowHeight
                color: selected ? Palette.activeBg : rowArea.containsMouse ? Palette.hoverBg : (modelData.connected ? Palette.activeBg : "transparent")
                border.width: (!selected && modelData.connected) ? 1 : 0
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
                        onClicked: root.activateNetwork(modelData)
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
                        text: {
                            const s = modelData.signalStrength;
                            if (s >= Palette.sigHigh)
                                return "󰤨";
                            if (s >= Palette.sigMed)
                                return "󰤥";
                            if (s >= Palette.sigLow)
                                return "󰤢";
                            return "󰤟";
                        }
                        color: selected ? Palette.fg : modelData.connected ? Palette.accent : rowArea.containsMouse ? Palette.fg : Palette.dim
                        font.family: Palette.font
                        font.pixelSize: Palette.px13
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 82
                        text: modelData.name || "Hidden network"
                        color: selected ? Palette.fg : (modelData.connected || rowArea.containsMouse) ? Palette.fg : Palette.dim
                        font.family: Palette.font
                        font.pixelSize: Palette.px12
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        text: "󰌾"
                        color: selected ? Palette.fg : rowArea.containsMouse ? Palette.fg : Palette.dim
                        font.family: Palette.font
                        font.pixelSize: Palette.px12
                        visible: modelData.security !== WifiSecurityType.Open && modelData.security !== WifiSecurityType.Unknown
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰅖"
                        color: selected ? Palette.fg : forgetArea.containsMouse ? Palette.fg : Palette.dim
                        font.family: Palette.font
                        font.pixelSize: Palette.px13
                        visible: modelData.known && !modelData.connected
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
        Column {
            id: authCol
            visible: root.authTarget !== null
            width: parent.width
            spacing: Palette.popupSpacing
            Text {
                width: parent.width
                text: "  " + (root.authTarget?.name ?? "Wi-Fi password")
                color: Palette.fg
                font.family: Palette.font
                font.pixelSize: Palette.px12
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                visible: root.authError !== ""
                height: visible ? implicitHeight : 0
                text: root.authError
                color: root.pendingNetwork ? Palette.dim : Palette.danger
                font.family: Palette.font
                font.pixelSize: Palette.px12
                wrapMode: Text.WordWrap
            }
            Rectangle {
                width: parent.width
                height: Palette.rowHeight
                color: Palette.surface
                border.width: 1
                border.color: Palette.border
                TextInput {
                    id: field
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Palette.fg
                    echoMode: TextInput.Password
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                    Keys.onReturnPressed: root.doConnect()
                    Keys.onEnterPressed: root.doConnect()
                }
            }
            Row {
                width: parent.width
                spacing: Palette.popupSpacing
                PopupButton {
                    label: "Cancel"
                    selected: root.selectedButton === 0
                    onHovered: root.selectedButton = 0
                    onClicked: {
                        root.selectedButton = 0;
                        root.cancelAuth();
                    }
                }
                PopupButton {
                    label: "Connect"
                    accent: true
                    selected: root.selectedButton === 1
                    onHovered: root.selectedButton = 1
                    onClicked: {
                        root.selectedButton = 1;
                        root.doConnect();
                    }
                }
            }
        }
        HintText {
            id: hint
            text: root.authTarget === null ? "jk move · Tab header · ↵ connect · d forget · s scan · e on/off" : "↵ connect · Esc back · Tab buttons"
        }
    }
}
