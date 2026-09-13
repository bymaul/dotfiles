import QtQuick
import Quickshell
import Quickshell.Networking
import "../components"
import "../Palette.js" as Palette
BasePopup {
    id: root
    implicitWidth: Palette.popupWidth
    implicitHeight: Palette.listHeight(Palette.listVisible) + 36 + 36 + Palette.popupSpacing * 3 + 16 + hint.implicitHeight
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.activateNetwork(root.selectedNetwork()) }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.activateNetwork(root.selectedNetwork()) }
    Shortcut { sequence: "d"; enabled: root.visible; onActivated: root.forgetSelected() }
    Shortcut { sequence: "Delete"; enabled: root.visible; onActivated: root.forgetSelected() }
    Shortcut { sequence: "s"; enabled: root.visible; onActivated: root.toggleScan() }
    Shortcut { sequence: "e"; enabled: root.visible; onActivated: root.toggleWifiEnabled() }
    onVisibleChanged: {
        if (visible)
            wifiList.currentIndex = 0;
    }
    function stepSelection(dir: int): void {
        if (wifiList.count === 0)
            return;
        wifiList.currentIndex = Palette.clamp(wifiList.currentIndex + dir, 0, wifiList.count - 1);
        wifiList.positionViewAtIndex(wifiList.currentIndex, ListView.Contain);
    }
    function selectedNetwork(): var {
        const nets = bar.wifiDevice?.networks.values ?? [];
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
        bar.showPasswordDialog(network);
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
                text: bar.connectedWifi ? "󰤨 " + bar.connectedWifi.name : bar.wifiDevice?.networks.values.find(n => n.state === ConnectionState.Connecting) ? "󰤭 Connecting..." : Networking.wifiEnabled ? "󰤭 Not connected" : "󰤯 Wi-Fi off"
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
                onClicked: root.toggleWifiEnabled()
            }
            PopupButton {
                label: bar.wifiDevice?.scannerEnabled ? "󰑓  Scanning..." : "󰑐  Scan"
                onClicked: root.toggleScan()
            }
        }
        ListView {
            id: wifiList
            width: parent.width
            height: Palette.listHeight(Palette.listVisible)
            clip: true
            model: bar.wifiDevice ? bar.wifiDevice.networks : null
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
                color: selected ? Palette.accent : rowArea.containsMouse ? Palette.hoverBg : (modelData.connected ? Palette.activeBg : "transparent")
                border.width: selected ? 1 : 0
                border.color: selected ? Palette.accent : modelData.connected ? Palette.accent : Palette.dim
                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
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
                        color: selected ? Palette.onAccent : modelData.connected ? Palette.accent : rowArea.containsMouse ? Palette.fg : Palette.dim
                        font.family: Palette.font
                        font.pixelSize: Palette.px13
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 82
                        text: modelData.name || "Hidden network"
                        color: selected ? Palette.onAccent : (modelData.connected || rowArea.containsMouse) ? Palette.fg : Palette.dim
                        font.family: Palette.font
                        font.pixelSize: Palette.px12
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        text: "󰌾"
                        color: selected ? Palette.onAccent : rowArea.containsMouse ? Palette.fg : Palette.dim
                        font.family: Palette.font
                        font.pixelSize: Palette.px12
                        visible: modelData.security !== WifiSecurityType.Open && modelData.security !== WifiSecurityType.Unknown
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰅖"
                        color: selected ? Palette.onAccent : forgetArea.containsMouse ? Palette.fg : Palette.dim
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
        HintText {
            id: hint
            text: "↵ connect · d forget · s scan · e on/off"
        }
    }
}
