import QtQuick
import Quickshell
import Quickshell.Networking
import "../components"
import "../Palette.js" as Palette
BasePopup {
    id: root
    anchorMode: "center"
    focusTarget: field
    implicitWidth: Palette.popupWidth
    implicitHeight: root.authError !== "" ? 172 : 150
    function quitArmed(): bool {
        return !field.activeFocus;
    }
    property int selectedButton: 1
    Shortcut { sequence: "h"; enabled: root.visible && !field.activeFocus; onActivated: root.selectedButton = 0 }
    Shortcut { sequence: "l"; enabled: root.visible && !field.activeFocus; onActivated: root.selectedButton = 1 }
    Shortcut { sequence: "Left"; enabled: root.visible && !field.activeFocus; onActivated: root.selectedButton = 0 }
    Shortcut { sequence: "Right"; enabled: root.visible && !field.activeFocus; onActivated: root.selectedButton = 1 }
    Shortcut { sequence: "Tab"; enabled: root.visible && !field.activeFocus; onActivated: root.selectedButton = (root.selectedButton + 1) % 2 }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible && !field.activeFocus; onActivated: root.selectedButton = (root.selectedButton + 1) % 2 }
    Shortcut { sequence: "Space"; enabled: root.visible && !field.activeFocus; onActivated: root.activateSelectedButton() }
    Shortcut { sequence: "Return"; enabled: root.visible && !field.activeFocus; onActivated: root.activateSelectedButton() }
    Shortcut { sequence: "Enter"; enabled: root.visible && !field.activeFocus; onActivated: root.activateSelectedButton() }
    property var targetNetwork: null
    property string authError: ""
    property var pendingNetwork: null
    onVisibleChanged: {
        if (visible) {
            selectedButton = 1;
            pendingNetwork = null;
        }
    }
    onTargetNetworkChanged: authError = ""
    function cancelDialog(): void {
        root.close();
        root.authError = "";
        field.text = "";
    }
    function activateSelectedButton(): void {
        if (selectedButton === 0)
            root.cancelDialog();
        else
            root.doConnect();
    }
    function resolveNetwork(): var {
        const name = root.targetNetwork?.name;
        if (!name || !bar.wifiDevice?.networks)
            return root.targetNetwork;
        return (bar.wifiDevice.networks.values ?? []).find(n => n && n.name === name) ?? root.targetNetwork;
    }
    function doConnect(): void {
        const net = root.resolveNetwork();
        if (!net)
            return;
        root.authError = "";
        root.pendingNetwork = net;
        net.connectWithPsk(field.text);
        root.visible = false;
        bar.closePasswordAndControl();
        field.text = "";
    }
    Connections {
        target: root.pendingNetwork
        enabled: root.pendingNetwork !== null
        function onConnectedChanged() {
            if (root.pendingNetwork?.connected)
                root.pendingNetwork = null;
        }
        function onConnectionFailed(reason) {
            const net = root.pendingNetwork;
            root.pendingNetwork = null;
            if (net && net.known && !net.connected)
                net.forget();
            root.targetNetwork = net;
            root.authError = (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout) ? "Wrong password, try again" : "Connection failed (" + ConnectionFailReason.toString(reason) + ")";
            root.visible = true;
        }
    }
    PopupCard {
        Text {
            width: parent.width
            text: "󰌾  " + (root.targetNetwork?.name ?? "Wi-Fi password")
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
            color: Palette.danger
            font.family: Palette.font
            font.pixelSize: Palette.px12
            wrapMode: Text.Wrap
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
                    root.cancelDialog();
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
}
