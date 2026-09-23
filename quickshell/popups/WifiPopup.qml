import QtQuick
import Quickshell
import Quickshell.Networking
import "../components"
import "../services" as Services
DeviceListBase {
    id: root
    implicitWidth: Services.Theme.popupWidth
    implicitHeight: (root.authTarget === null ? wifiList.height : authCol.height) + 36 + 36 + Services.Theme.popupSpacing * 3 + 16 + hint.implicitHeight
    targetList: wifiList
    listBlocked: root.authTarget !== null
    Shortcut { sequence: "h"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = 0 }
    Shortcut { sequence: "l"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = 1 }
    Shortcut { sequence: "Left"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = 0 }
    Shortcut { sequence: "Right"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = 1 }
    Shortcut { sequence: "Tab"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = (root.selectedButton + 1) % 2 }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = (root.selectedButton + 1) % 2 }
    Shortcut { sequence: "Space"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.activateSelectedButton() }
    Shortcut { sequence: "Return"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.activateSelectedButton() }
    Shortcut { sequence: "Enter"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.activateSelectedButton() }
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
            root.resetNav();
        } else {
            root.cancelAuth();
        }
    }
    function activateRow(): void {
        root.activateNetwork(root.selectedNetwork());
    }
    function forgetRow(): void {
        root.forgetSelected();
    }
    function selectedNetwork(): var {
        const nets = Services.Wifi.device?.networks?.values ?? [];
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
        if (!name || !Services.Wifi.device?.networks)
            return root.authTarget;
        return (Services.Wifi.device.networks.values ?? []).find(n => n && n.name === name) ?? root.authTarget;
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
        if (!Services.Wifi.device)
            return;
        Services.Wifi.device.scannerEnabled = !Services.Wifi.device.scannerEnabled;
        if (Services.Wifi.device.scannerEnabled)
            scanTimeout.restart();
        else
            scanTimeout.stop();
    }
    Timer {
        id: scanTimeout
        interval: Services.Theme.scanTimeout
        repeat: false
        onTriggered: {
            if (Services.Wifi.device)
                Services.Wifi.device.scannerEnabled = false;
        }
    }
    function toggleEnabled(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }
    PopupCard {
        DeviceHeader {
            statusText: Services.Wifi.connected ? "󰤨 " + Services.Wifi.connected.name : (Services.Wifi.device?.networks?.values ?? []).find(n => n && n.state === ConnectionState.Connecting) ? "󰤭 Connecting..." : Networking.wifiEnabled ? "󰤭 Not connected" : "󰤯 Wi-Fi off"
            statusColor: Services.Wifi.connected ? Services.Theme.fg : Services.Theme.dim
            enableLabel: Networking.wifiEnabled ? "󰖪  Disable" : "󰖩  Enable"
            scanLabel: Services.Wifi.device?.scannerEnabled ? "󰑓  Scanning..." : "󰑐  Scan"
            headIndex: root.headIndex
            onHeadHovered: index => root.headIndex = index
            onEnableClicked: root.toggleEnabled()
            onScanClicked: root.toggleScan()
        }
        ListView {
            id: wifiList
            visible: root.authTarget === null
            width: parent.width
            height: Services.Theme.listHeight(Services.Theme.listVisible)
            clip: true
            model: Services.Wifi.device?.networks ?? null
            spacing: Services.Theme.listSpacing
            onCountChanged: clampListView(wifiList)
            delegate: ResultRow {
                id: row
                required property var modelData
                required property int index
                selected: wifiList.currentIndex === index
                highlighted: modelData.connected
                rowHeight: Services.Theme.listRowHeight
                selectedColor: Services.Theme.activeBg
                onHovered: root.selectRow(index)
                onClicked: root.activateNetwork(modelData)
                Row {
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                    }
                    spacing: Services.Theme.popupSpacing
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: Services.Wifi.signalGlyph(modelData.signalStrength)
                        color: row.selected ? Services.Theme.fg : modelData.connected ? Services.Theme.accent : row.isHovered ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px13
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 82
                        text: modelData.name || "Hidden network"
                        color: row.selected ? Services.Theme.fg : (modelData.connected || row.isHovered) ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        text: "󰌾"
                        color: row.selected ? Services.Theme.fg : row.isHovered ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                        visible: modelData.security !== WifiSecurityType.Open && modelData.security !== WifiSecurityType.Unknown
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰅖"
                        color: row.selected ? Services.Theme.fg : forgetArea.containsMouse ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px13
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
            spacing: Services.Theme.popupSpacing
            Text {
                width: parent.width
                text: "  " + (root.authTarget?.name ?? "Wi-Fi password")
                color: Services.Theme.fg
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                visible: root.authError !== ""
                height: visible ? implicitHeight : 0
                text: root.authError
                color: root.pendingNetwork ? Services.Theme.dim : Services.Theme.danger
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
                wrapMode: Text.WordWrap
            }
            Rectangle {
                width: parent.width
                height: Services.Theme.rowHeight
                color: Services.Theme.surface
                border.width: 1
                border.color: Services.Theme.border
                TextInput {
                    id: field
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Services.Theme.fg
                    echoMode: TextInput.Password
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    Keys.onReturnPressed: root.doConnect()
                    Keys.onEnterPressed: root.doConnect()
                }
            }
            ConfirmRow {
                choice: root.selectedButton
                noLabel: "Cancel"
                yesLabel: "Connect"
                accentYes: true
                onHovered: index => root.selectedButton = index
                onPicked: index => {
                    root.selectedButton = index;
                    if (index === 0)
                        root.cancelAuth();
                    else
                        root.doConnect();
                }
            }
        }
        HintText {
            id: hint
            text: root.authTarget === null ? "jk move · Tab header · ↵ connect · d forget · s scan · e on/off" : "↵ connect · Esc back · Tab buttons"
        }
    }
}
