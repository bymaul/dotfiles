import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import "../Palette.js" as Palette

BasePopup {
    id: passwordDialog

    anchorMode: "center"

    implicitWidth: 280

    // Error line adds ~22px only when shown; otherwise the dialog
    // would keep a permanent blank gap at the bottom.
    implicitHeight: passwordDialog.authError !== "" ? 172 : 150

    Shortcut {
        sequence: "Escape"
        onActivated: bar.closePopups()
    }

    // 0 = Cancel, 1 = Connect. h/l only reach these when the
    // password field is unfocused (it consumes keys for cursor
    // movement while focused); Enter always connects from the field.
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
            selectedButton = 1
            pendingNetwork = null
            wifiPassword.forceActiveFocus()
        }
    }

    // Cleared on a new network or a fresh attempt - but NOT on open,
    // since the failure handler reopens the dialog to SHOW the error.
    onNetworkChanged: authError = ""

    function cancelDialog(): void {
        passwordDialog.visible = false
        passwordDialog.authError = ""
        wifiPassword.text = ""
    }

    function activateSelectedButton(): void {
        if (selectedButton === 0)
            passwordDialog.cancelDialog()
        else
            passwordDialog.doConnect()
    }

    function resolveNetwork(): var {
        // The model may rebuild objects (e.g. after a forget), so
        // re-resolve by name instead of trusting a stored reference.
        const name = passwordDialog.network?.name

        if (!name || !bar.wifiDevice)
            return passwordDialog.network

        return bar.wifiDevice.networks.values.find(
            n => n.name === name
        ) ?? passwordDialog.network
    }

    function doConnect(): void {
        const net = passwordDialog.resolveNetwork()

        if (!net)
            return

        passwordDialog.authError = ""
        passwordDialog.pendingNetwork = net
        net.connectWithPsk(wifiPassword.text)

        passwordDialog.visible = false
        bar.closePasswordAndControl()

        wifiPassword.text = ""
    }

    // A failed attempt drops the junk profile NM saved for it and
    // reopens the dialog with the reason instead of vanishing
    // silently. Row-click connects on known networks set no pending
    // ref, so this only fires for password attempts (which always
    // start from an unknown network, making forget() safe here).
    Connections {
        target: passwordDialog.pendingNetwork

        function onConnectionFailed(reason) {
            const net = passwordDialog.pendingNetwork

            passwordDialog.pendingNetwork = null

            if (net && net.known && !net.connected)
                net.forget()

            passwordDialog.network = net

            passwordDialog.authError =
                (reason === ConnectionFailReason.NoSecrets ||
                    reason === ConnectionFailReason.WifiAuthTimeout)
                ? "Wrong password, try again"
                : "Connection failed (" +
                    ConnectionFailReason.toString(reason) + ")"

            passwordDialog.visible = true
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
                text: "󰌾  " +
                    (passwordDialog.network?.name ??
                     "Wi-Fi password")

                color: Palette.fg

                font.family:
                    Palette.font

                font.pixelSize: Palette.px12
                elide: Text.ElideRight
            }

            Text {
                width: parent.width

                visible: passwordDialog.authError !== ""
                height: visible ? implicitHeight : 0

                text: passwordDialog.authError

                color: Palette.danger

                font.family:
                    Palette.font

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

                    verticalAlignment:
                        TextInput.AlignVCenter

                    color: Palette.fg

                    echoMode:
                        TextInput.Password

                    font.family:
                        Palette.font

                    font.pixelSize: Palette.px12

                    Keys.onReturnPressed: {
                        passwordDialog.doConnect()
                    }
                    Keys.onEnterPressed: {
                        passwordDialog.doConnect()
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
                    border.color: passwordDialog.selectedButton === 0
                        ? Palette.fg : Palette.dim

                    Text {
                        anchors.centerIn: parent

                        text: "Cancel"

                        color: Palette.fg

                        font.family:
                            Palette.font

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
                    border.color: passwordDialog.selectedButton === 1
                        ? Palette.fg : Palette.accent

                    Text {
                        anchors.centerIn: parent

                        text: "Connect"

                        color: Palette.onAccent

                        font.family:
                            Palette.font

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