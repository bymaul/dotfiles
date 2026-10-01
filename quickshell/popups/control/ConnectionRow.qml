import QtQuick
import Quickshell.Bluetooth
import "../../services" as Services

Item {
    id: root
    width: parent.width
    height: visible ? 18 : 0
    visible: wifiVisible || btVisible

    readonly property var wifiNet: Services.Wifi.connected
    readonly property bool isWired: Services.Wifi.wiredConnected
    readonly property bool wifiVisible: !!(root.isWired || wifiNet)
    readonly property string wifiGlyph: root.isWired ? "󰈀" : wifiNet ? Services.Wifi.signalGlyph(wifiNet.signalStrength) : "󰤯"
    readonly property string wifiText: root.isWired ? (Services.Wifi.wiredDevice?.name ?? "Wired") : (wifiNet?.name || "Wi-Fi")

    readonly property var btDevs: (Bluetooth.devices?.values ?? []).filter(d => d && (d.connected || d.state === BluetoothDeviceState.Connected))
    readonly property bool btVisible: root.btDevs.length > 0
    readonly property string btText: {
        if (!root.btVisible)
            return "";
        const sorted = root.btDevs.slice().sort((a, b) => String(a.name || a.deviceName || a.address).localeCompare(String(b.name || b.deviceName || b.address)));
        const first = sorted[0].name || sorted[0].deviceName || sorted[0].address || "Bluetooth";
        return sorted.length > 1 ? first + " +" + (sorted.length - 1) : first;
    }

    readonly property real glyphW: 16
    readonly property real gap: 4
    readonly property real midGap: 12
    readonly property real sideMargins: 8
    readonly property real sideCap: root.wifiVisible && root.btVisible ? Math.max(40, (parent.width - root.sideMargins - root.glyphW * 2 - root.gap * 2 - root.midGap) / 2) : parent.width - root.sideMargins - root.glyphW - root.gap

    Row {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, parent.width - root.sideMargins)
        spacing: root.gap
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.wifiVisible
            width: root.glyphW
            horizontalAlignment: Text.AlignHCenter
            text: root.wifiGlyph
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.wifiVisible
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.sideCap)
            text: root.wifiText
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px11
        }
        Item {
            width: root.midGap
            height: 1
            visible: root.wifiVisible && root.btVisible
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.btVisible
            width: root.glyphW
            horizontalAlignment: Text.AlignHCenter
            text: "󰂱"
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.btVisible
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.sideCap)
            text: root.btText
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px11
        }
    }
}
