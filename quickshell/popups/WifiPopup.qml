import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import "../Palette.js" as Palette

BasePopup {
    id: wifiPopup

    implicitWidth: Palette.popupWidth
    implicitHeight: 446

    Shortcut {
        sequence: "Escape"
        onActivated: bar.closePopups()
    }

    onVisibleChanged: {
        if (visible)
            wifiList.currentIndex = 0
    }

    function stepSelection(dir: int): void {
        if (wifiList.count === 0)
            return

        wifiList.currentIndex = Math.max(0,
            Math.min(wifiList.count - 1, wifiList.currentIndex + dir))
        wifiList.positionViewAtIndex(wifiList.currentIndex, ListView.Contain)
    }

    function selectedNetwork(): var {
        const nets = bar.wifiDevice?.networks.values ?? []

        if (wifiList.currentIndex < 0 || wifiList.currentIndex >= nets.length)
            return null

        return nets[wifiList.currentIndex]
    }

    function activateNetwork(network): void {
        if (!network)
            return

        if (network.connected) {
            network.disconnect()
            return
        }

        if (network.known) {
            network.connect()
            return
        }

        bar.showPasswordDialog(network)
    }

    function forgetSelected(): void {
        const net = wifiPopup.selectedNetwork()

        if (net && net.known && !net.connected)
            net.forget()
    }

    function toggleScan(): void {
        if (!bar.wifiDevice)
            return

        bar.wifiDevice.scannerEnabled = !bar.wifiDevice.scannerEnabled

        if (bar.wifiDevice.scannerEnabled)
            scanTimeout.restart()
        else
            scanTimeout.stop()
    }

    // Continuous scanning drains battery: a manual scan gets one
    // 15s pass, then the radio goes quiet again.
    Timer {
        id: scanTimeout

        interval: 15000
        repeat: false

        onTriggered: {
            if (bar.wifiDevice)
                bar.wifiDevice.scannerEnabled = false
        }
    }

    function toggleWifiEnabled(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled
    }

    // Letter shortcuts stay scoped to the open popup so they never
    // leak into typing elsewhere.
    Shortcut {
        sequence: "j"
        enabled: wifiPopup.visible
        onActivated: wifiPopup.stepSelection(1)
    }
    Shortcut {
        sequence: "k"
        enabled: wifiPopup.visible
        onActivated: wifiPopup.stepSelection(-1)
    }
    Shortcut {
        sequence: "Return"
        enabled: wifiPopup.visible
        onActivated: wifiPopup.activateNetwork(wifiPopup.selectedNetwork())
    }
    Shortcut {
        sequence: "Enter"
        enabled: wifiPopup.visible
        onActivated: wifiPopup.activateNetwork(wifiPopup.selectedNetwork())
    }
    Shortcut {
        sequence: "d"
        enabled: wifiPopup.visible
        onActivated: wifiPopup.forgetSelected()
    }
    Shortcut {
        sequence: "Delete"
        enabled: wifiPopup.visible
        onActivated: wifiPopup.forgetSelected()
    }
    Shortcut {
        sequence: "s"
        enabled: wifiPopup.visible
        onActivated: wifiPopup.toggleScan()
    }
    Shortcut {
        sequence: "e"
        enabled: wifiPopup.visible
        onActivated: wifiPopup.toggleWifiEnabled()
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

            Rectangle {
                width: parent.width
                height: Palette.rowHeight

                radius: 0

                color: "transparent"
                border.width: 0

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }

                    width: parent.width - 20

                    text: bar.connectedWifi
                        ? "󰤨 " + bar.connectedWifi.name
                        : bar.wifiDevice?.networks.values.find(
                            n => n.state ===
                                ConnectionState.Connecting
                        )
                            ? "󰤭 Connecting..."
                            : Networking.wifiEnabled
                                ? "󰤭 Not connected"
                                : "󰤯 Wi-Fi off"

                    color: bar.connectedWifi
                        ? Palette.fg
                        : Palette.dim

                    font.family:
                        Palette.font

                    font.pixelSize: Palette.px12

                    elide: Text.ElideRight
                }
            }

            Row {
                width: parent.width
                height: Palette.rowHeight
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: parent.height

                    radius: 0

                    color: enableHover.containsMouse
                        ? Palette.hoverBg : Palette.surface
                    border.width: 0

                    Text {
                        anchors.centerIn: parent

                        text: Networking.wifiEnabled
                            ? "󰖪  Disable"
                            : "󰖩  Enable"

                        color: Networking.wifiEnabled
                            ? Palette.dim
                            : Palette.accent

                        font.family:
                            Palette.font

                        font.pixelSize: Palette.px12
                    }

                    MouseArea {
                        id: enableHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            Networking.wifiEnabled =
                                !Networking.wifiEnabled
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: parent.height

                    radius: 0

                    color: scanHover.containsMouse
                        ? Palette.hoverBg : Palette.surface
                    border.width: 0

                    Text {
                        anchors.centerIn: parent

                        text: bar.wifiDevice?.scannerEnabled
                            ? "󰑓  Scanning..."
                            : "󰑐  Scan"

                        color: Palette.dim

                        font.family:
                            Palette.font

                        font.pixelSize: Palette.px12
                    }

                    MouseArea {
                        id: scanHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            wifiPopup.toggleScan()
                        }
                    }
                }
            }

            ListView {
                id: wifiList

                width: parent.width
                height: parent.height - 36 - 36 - 14 - 24

                clip: true

                model: bar.wifiDevice
                    ? bar.wifiDevice.networks
                    : null

                spacing: 4

                onCountChanged: {
                    if (currentIndex >= count)
                        currentIndex = Math.max(0, count - 1)
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool selected:
                        wifiList.currentIndex === index

                    width: wifiList.width
                    height: Palette.listRowHeight

                    radius: 0

                    color: selected ? Palette.accent
                        : rowHover.containsMouse ? Palette.hoverBg
                        : (modelData.connected ? Palette.activeBg : "transparent")
                    border.width: selected ? 1 : 0
                    border.color: selected ? Palette.accent
                        : modelData.connected ? Palette.accent : Palette.dim

                    MouseArea {
                        id: rowHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            wifiPopup.activateNetwork(modelData)
                        }
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

                            width: 18

                            text: {
                                const s = modelData.signalStrength
                                if (s >= -50) return "󰤨"
                                if (s >= -67) return "󰤥"
                                if (s >= -75) return "󰤢"
                                return "󰤯"
                            }

                            color: selected ? Palette.onAccent
                                : modelData.connected ? Palette.accent
                                : rowHover.containsMouse ? Palette.fg : Palette.dim

                            font.family:
                                Palette.font

                            font.pixelSize: Palette.px13
                        }

                        Text {
                            anchors.verticalCenter:
                                parent.verticalCenter

                            width: parent.width - 82

                            text: modelData.name ||
                                "Hidden network"

                            color: selected ? Palette.onAccent
                                : (modelData.connected || rowHover.containsMouse)
                                ? Palette.fg : Palette.dim

                            font.family:
                                Palette.font

                            font.pixelSize: Palette.px12

                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.verticalCenter:
                                parent.verticalCenter

                            width: 16

                            text: "󰌾"

                            color: selected ? Palette.onAccent
                                : rowHover.containsMouse ? Palette.fg : Palette.dim

                            font.family:
                                Palette.font

                            font.pixelSize: Palette.px12

                            visible:
                                modelData.security !==
                                    WifiSecurityType.Open &&
                                modelData.security !==
                                    WifiSecurityType.Unknown
                        }

                        Text {
                            anchors.verticalCenter:
                                parent.verticalCenter

                            width: 24

                            horizontalAlignment:
                                Text.AlignHCenter

                            text: "󰅖"

                            color: selected ? Palette.onAccent
                                : forgetHover.containsMouse
                                ? Palette.fg
                                : Palette.dim

                            font.family:
                                Palette.font

                            font.pixelSize: Palette.px13

                            visible:
                                modelData.known &&
                                !modelData.connected

                    MouseArea {
                        id: forgetHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape:
                            Qt.PointingHandCursor

                        onClicked: mouse => {
                            mouse.accepted = true
                            modelData.forget()
                        }
                    }
                        }
                    }
                }
            }

            Text {
                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                text: "↵ connect · d forget · s scan · e on/off"

                wrapMode: Text.WordWrap

                color: Palette.dim

                font.family: Palette.font
                font.pixelSize: Palette.px10
            }
        }
    }
}
