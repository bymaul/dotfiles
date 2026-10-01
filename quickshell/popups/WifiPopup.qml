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
    Shortcut { sequence: "j"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = (root.selectedButton + 1) % 2 }
    Shortcut { sequence: "k"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.selectedButton = (root.selectedButton + 1) % 2 }
    Shortcut { sequence: "Return"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.activateSelectedButton() }
    Shortcut { sequence: "Enter"; enabled: root.visible && root.authTarget !== null && !field.activeFocus; onActivated: root.activateSelectedButton() }
    property var authTarget: null
    property string authBssid: ""
    property string authError: ""
    property var pendingNetwork: null
    property int selectedButton: 1
    function quitArmed(): bool {
        return root.authTarget === null;
    }
    function cancelOrClose(): void {
        if (root.authTarget)
            root.cancelAuth();
        else
            root.close();
    }
    onVisibleChanged: {
        Services.Wifi.listActive = visible;
        if (visible) {
            root.resetNav();
            root.autoScanOnOpen();
        } else {
            root.cancelAuth();
            Services.Wifi.snapshotNetworks();
        }
    }
    function autoScanOnOpen(): void {
        const dev = Services.Wifi.device;
        if (!dev || !Services.Wifi.enabled || !Services.Wifi.hardwareEnabled || dev.scannerEnabled)
            return;
        if (Services.Wifi.connected || Services.Wifi.connecting)
            return;
        dev.scannerEnabled = true;
        scanTimeout.restart();
    }
    function activateRow(): void {
        root.activateNetwork(root.selectedNetwork());
    }
    function forgetRow(): void {
        root.forgetSelected();
    }
    function selectedNetwork(): var {
        const nets = Services.Wifi.sortedNetworks;
        if (wifiList.currentIndex < 0 || wifiList.currentIndex >= nets.length)
            return null;
        return nets[wifiList.currentIndex];
    }
    function activateNetwork(network: var): void {
        if (!network || network.stateChanging)
            return;
        if (network.connected) {
            network.disconnect();
            return;
        }
        if (network.state === ConnectionState.Connecting)
            return;
        if (network.known) {
            network.connect();
            return;
        }
        root.enterAuth(network);
    }
    function enterAuth(network: var): void {
        root.authTarget = network;
        root.authBssid = String(network?.bssid ?? network?.macAddress ?? "");
        root.authError = "";
        root.pendingNetwork = null;
        connectTimeout.stop();
        root.selectedButton = 1;
        root.focusTarget = field;
        field.forceActiveFocus();
    }
    function cancelAuth(): void {
        connectTimeout.stop();
        root.authTarget = null;
        root.authBssid = "";
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
        if (!root.authTarget)
            return null;
        const live = Services.Wifi.rawNetworks;
        if (live.includes(root.authTarget))
            return root.authTarget;
        const key = Services.Wifi.networkKey(root.authTarget);
        if (key !== "") {
            const byKey = live.find(n => n && Services.Wifi.networkKey(n) === key);
            if (byKey)
                return byKey;
        }
        const name = root.authTarget?.name;
        if (!name)
            return root.authTarget;
        const sameName = live.filter(n => n && n.name === name);
        if (sameName.length === 0)
            return root.authTarget;
        const wantSec = root.authTarget?.security;
        return sameName.find(n => n && n.security === wantSec) ?? sameName[0];
    }
    function doConnect(): void {
        if (root.pendingNetwork)
            return;
        const net = root.resolveAuthNetwork();
        if (!net || net.stateChanging)
            return;
        const psk = String(field.text ?? "");
        if (psk === "") {
            root.authError = "Enter the Wi-Fi password";
            root.focusTarget = field;
            field.forceActiveFocus();
            return;
        }
        if (psk.length < 8) {
            root.authError = "Password must be at least 8 characters";
            root.focusTarget = field;
            field.forceActiveFocus();
            return;
        }
        if (psk.length > 256)
            return;
        root.authError = "Connecting...";
        root.pendingNetwork = net;
        connectTimeout.restart();
        net.connectWithPsk(psk);
        field.text = "";
        field.forceActiveFocus();
    }
    Timer {
        id: connectTimeout
        interval: 20000
        repeat: false
        onTriggered: {
            if (!root.pendingNetwork)
                return;
            const net = root.pendingNetwork;
            root.pendingNetwork = null;
            root.authTarget = net;
            root.authError = "Timed out - try again";
            root.focusTarget = field;
            field.forceActiveFocus();
        }
    }
    Connections {
        target: root.pendingNetwork
        enabled: root.pendingNetwork !== null
        function onConnectedChanged() {
            if (root.pendingNetwork?.connected) {
                connectTimeout.stop();
                root.pendingNetwork = null;
                if (bar && typeof bar.closePopups === "function")
                    bar.closePopups();
                else
                    root.close();
            }
        }
        function onConnectionFailed(reason) {
            connectTimeout.stop();
            const net = root.pendingNetwork;
            root.pendingNetwork = null;
            root.authTarget = net ?? root.authTarget;
            root.authError = (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout) ? "Wrong password, try again" : "Connection failed (" + ConnectionFailReason.toString(reason) + ")";
            root.focusTarget = field;
            field.forceActiveFocus();
        }
    }
    function forgetSelected(): void {
        const net = root.selectedNetwork();
        if (net && net.known && !net.connected && !net.stateChanging)
            net.forget();
    }
    function toggleScan(): void {
        const dev = Services.Wifi.device;
        if (!dev || !Services.Wifi.enabled || !Services.Wifi.hardwareEnabled)
            return;
        dev.scannerEnabled = !dev.scannerEnabled;
        if (dev.scannerEnabled)
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
        if (!Services.Wifi.hardwareEnabled)
            return;
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }
    function headerStatus(): string {
        if (!Services.Wifi.device)
            return "No Wi-Fi device found";
        if (!Services.Wifi.hardwareEnabled)
            return "󰤯 Wi-Fi blocked (rfkill)";
        if (!Services.Wifi.enabled)
            return "󰤯 Wi-Fi off";
        if (Services.Wifi.connected)
            return "󰤨 " + (Services.Wifi.connected.name || "Connected");
        if (Services.Wifi.connecting)
            return "󰤭 Connecting to " + (Services.Wifi.connecting.name || "…") + "…";
        if (Services.Wifi.sortedNetworks.length === 0)
            return Services.Wifi.scanning ? "󰑓  Scanning..." : "󰤭 No networks found";
        return "󰤭 Not connected";
    }
    function rowSubText(net: var): string {
        if (!net)
            return "";
        if (net.connected)
            return "Connected";
        if (net.state === ConnectionState.Connecting || net.stateChanging)
            return "Connecting...";
        if (net.known)
            return "Saved";
        return net.security !== WifiSecurityType.Open && net.security !== WifiSecurityType.Unknown ? "Secured" : "Open";
    }
    PopupCard {
        DeviceHeader {
            statusText: root.headerStatus()
            statusColor: Services.Wifi.connected ? Services.Theme.fg : Services.Theme.dim
            enableLabel: Services.Wifi.enabled ? "󰖪  Disable" : "󰖩  Enable"
            scanLabel: Services.Wifi.scanning ? "󰑓  Scanning..." : "󰑐  Scan"
            onEnableClicked: root.toggleEnabled()
            onScanClicked: root.toggleScan()
        }
        Item {
            visible: root.authTarget === null
            width: parent.width
            height: Services.Theme.listHeight(Services.Theme.listVisible)
            ListView {
                id: wifiList
                anchors.fill: parent
                clip: true
                model: Services.Wifi.sortedNetworks
                spacing: Services.Theme.listSpacing
                onCountChanged: clampListView(wifiList)
                onModelChanged: clampListView(wifiList)
                delegate: ResultRow {
                    id: row
                    required property var modelData
                    required property int index
                    selected: wifiList.currentIndex === index
                    highlighted: row.busy || modelData.connected
                    rowHeight: Services.Theme.listRowHeight
                    readonly property bool busy: modelData.state === ConnectionState.Connecting || !!modelData.stateChanging
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
                        color: row.selected ? Services.Theme.accentFg : (modelData.connected || row.busy) ? Services.Theme.accent : row.isHovered ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px13
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 82
                        spacing: 2
                        Text {
                            width: parent.width
                            text: modelData.name || "Hidden network"
                            color: row.selected ? Services.Theme.accentFg : (modelData.connected || row.busy || row.isHovered) ? Services.Theme.fg : Services.Theme.dim
                            font.family: Services.Theme.font
                            font.pixelSize: Services.Theme.px12
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: root.rowSubText(modelData)
                            color: row.selected ? Services.Theme.accentFg : row.isHovered ? Services.Theme.fg : Services.Theme.dim
                            font.family: Services.Theme.font
                            font.pixelSize: Services.Theme.px10
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        text: "󰌾"
                        color: row.selected ? Services.Theme.accentFg : row.isHovered ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                        visible: modelData.security !== WifiSecurityType.Open && modelData.security !== WifiSecurityType.Unknown
                    }
                    ForgetButton {
                        selected: row.selected
                        visible: modelData.known && !modelData.connected && !row.busy
                        onForget: root.forgetSelected()
                    }
                }
            }
            }
            Text {
                anchors.centerIn: parent
                visible: !Services.Wifi.device
                text: 'No Wi-Fi device'
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
            }
            Text {
                anchors.centerIn: parent
                visible: Services.Wifi.device && !Services.Wifi.hardwareEnabled
                text: 'Wi-Fi blocked - check rfkill switch'
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
            }
            Text {
                anchors.centerIn: parent
                visible: Services.Wifi.device && Services.Wifi.hardwareEnabled && !Services.Wifi.enabled
                text: 'Wi-Fi is off - press e to enable'
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
            }
            Text {
                anchors.centerIn: parent
                visible: Services.Wifi.device && Services.Wifi.hardwareEnabled && Services.Wifi.enabled && Services.Wifi.sortedNetworks.length === 0
                text: Services.Wifi.scanning ? 'Scanning...' : 'No networks - press s to scan'
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
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
                    maximumLength: 256
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
            text: root.authTarget === null ? "jk navigate · d forget · s scan · e on/off" : "jk buttons · Enter connect · Esc back"
        }
    }
}
