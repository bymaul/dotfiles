import QtQuick
import Quickshell
import Quickshell.Networking
import "../Palette.js" as Palette

BasePopup {
    id: passwordDialog

    anchorMode: "center"

    implicitWidth: 280

    implicitHeight: passwordDialog.authError !== "" ? 172 : 150

    Shortcut {
        sequence: "Escape"
        onActivated: bar.closePopups()
    }

    // h/l are unreachable while the field has focus (it consumes
    // keys for cursor movement); Enter always connects.
    property int selectedButton: 1

    Shortcut {
        sequence: "h"
        enabled: passwordDialog.visible && !wifiPassword.activeFocus
        onActivated: passwordDialog.selectedButton = 0
    }
    Shortcut {
        sequence: "l"
        enabled: passwordDialog.visible && !wifiPassword.activeFocus
        onActivated: passwordDialog.selectedButton = 1
    }
    Shortcut {
        sequence: "Space"
        enabled: passwordDialog.visible && !wifiPassword.activeFocus
        onActivated: passwordDialog.activateSelectedButton()
    }
    Shortcut {
        sequence: "Return"
        enabled: passwordDialog.visible && !wifiPassword.activeFocus
        onActivated: passwordDialog.activateSelectedButton()
    }
    Shortcut {
        sequence: "Enter"
        enabled: passwordDialog.visible && !wifiPassword.activeFocus
        onActivated: passwordDialog.activateSelectedButton()
    }

    property var network: null
    property string authError: ""
    property var pendingNetwork: null

    onVisibleChanged: {
        if (visible) {
            selectedButton = 1;
            pendingNetwork = null;
            wifiPassword.forceActiveFocus();
        }
    }

    // NOT cleared on open: the failure handler reopens the dialog
    // to SHOW the error.
    onNetworkChanged: authError = ""

    function cancelDialog(): void {
        passwordDialog.visible = false;
        passwordDialog.authError = "";
        wifiPassword.text = "";
    }

    function activateSelectedButton(): void {
        if (selectedButton === 0)
            passwordDialog.cancelDialog();
        else
            passwordDialog.doConnect();
    }

    function resolveNetwork(): var {
        // The model may rebuild objects, so re-resolve by name
        // instead of trusting the stored reference.
        const name = passwordDialog.network?.name;

        if (!name || !bar.wifiDevice)
            return passwordDialog.network;

        return bar.wifiDevice.networks.values.find(n => n.name === name) ?? passwordDialog.network;
    }

    function doConnect(): void {
        const net = passwordDialog.resolveNetwork();

        if (!net)
            return;
        passwordDialog.authError = "";
        passwordDialog.pendingNetwork = net;
        net.connectWithPsk(wifiPassword.text);

        passwordDialog.visible = false;
        bar.closePasswordAndControl();

        wifiPassword.text = "";
    }

    // Failure drops the junk profile NM saved and reopens with the
    // reason. Only password attempts reach here (row clicks set no
    // pending ref), so forget() is safe.
    Connections {
        target: passwordDialog.pendingNetwork
        enabled: passwordDialog.pendingNetwork !== null

        // Success must release the ref too, or a later unrelated
        // failure from this network reopens the dialog bogusly.
        function onConnectedChanged() {
            if (passwordDialog.pendingNetwork?.connected)
                passwordDialog.pendingNetwork = null;
        }

        function onConnectionFailed(reason) {
            const net = passwordDialog.pendingNetwork;

            passwordDialog.pendingNetwork = null;

            if (net && net.known && !net.connected)
                net.forget();

            passwordDialog.network = net;

            passwordDialog.authError = (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout) ? "Wrong password, try again" : "Connection failed (" + ConnectionFailReason.toString(reason) + ")";

            passwordDialog.visible = true;
        }
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

            Text {
                width: parent.width
                text: "󰌾  " + (passwordDialog.network?.name ?? "Wi-Fi password")

                color: Palette.fg

                font.family: Palette.font

                font.pixelSize: Palette.px12
                elide: Text.ElideRight
            }

            Text {
                width: parent.width

                visible: passwordDialog.authError !== ""
                height: visible ? implicitHeight : 0

                text: passwordDialog.authError

                color: Palette.danger

                font.family: Palette.font

                font.pixelSize: Palette.px12

                wrapMode: Text.Wrap
            }

            Rectangle {
                width: parent.width
                height: Palette.rowHeight

                radius: 0

                color: Palette.surface
                border.width: 1
                border.color: Palette.border

                TextInput {
                    id: wifiPassword

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

                    Keys.onReturnPressed: {
                        passwordDialog.doConnect();
                    }
                    Keys.onEnterPressed: {
                        passwordDialog.doConnect();
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 32

                    radius: 0

                    color: Palette.surface

                    border.width: passwordDialog.selectedButton === 0 ? 1 : 0
                    border.color: passwordDialog.selectedButton === 0 ? Palette.fg : Palette.dim

                    Text {
                        anchors.centerIn: parent

                        text: "Cancel"

                        color: Palette.fg

                        font.family: Palette.font

                        font.pixelSize: Palette.px12
                    }

                    MouseArea {
                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: passwordDialog.cancelDialog()
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 32

                    radius: 0

                    color: Palette.accent

                    border.width: 1
                    border.color: passwordDialog.selectedButton === 1 ? Palette.fg : Palette.accent

                    Text {
                        anchors.centerIn: parent

                        text: "Connect"

                        color: Palette.onAccent

                        font.family: Palette.font

                        font.pixelSize: Palette.px12
                    }

                    MouseArea {
                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: passwordDialog.doConnect()
                    }
                }
            }
        }
    }
}
