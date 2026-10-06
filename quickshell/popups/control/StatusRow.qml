import QtQuick
import Quickshell.Bluetooth
import "../../services" as Services

Item {
    id: root
    width: parent.width
    height: 18

    readonly property var wifiNet: Services.Wifi.connected
    readonly property var connectingNet: Services.Wifi.connecting
    readonly property bool isWired: Services.Wifi.wiredConnected
    readonly property string wifiGlyph: root.isWired ? "󰈀" : wifiNet ? Services.Wifi.signalGlyph(wifiNet.signalStrength) : "󰤯"
    readonly property string wifiText: {
        if (root.isWired)
            return (Services.Wifi.wiredDevice?.name ?? "Wired");
        if (root.wifiNet)
            return (root.wifiNet.name || "Wi-Fi");
        if (root.connectingNet)
            return ((root.connectingNet.name || "Wi-Fi") + "…");
        if (!Services.Wifi.enabled)
            return "Wi-Fi off";
        return "Disconnected";
    }

    readonly property var btDevs: (Bluetooth.devices?.values ?? []).filter(d => d && (d.connected || d.state === BluetoothDeviceState.Connected))
    readonly property bool btEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property string btGlyph: root.btDevs.length > 0 ? "󰂱" : "󰂯"
    readonly property string btText: {
        if (root.btDevs.length > 0) {
            const sorted = root.btDevs.slice().sort((a, b) => String(a.name || a.deviceName || a.address).localeCompare(String(b.name || b.deviceName || b.address)));
            const first = sorted[0].name || sorted[0].deviceName || sorted[0].address || "Bluetooth";
            return sorted.length > 1 ? first + " +" + (sorted.length - 1) : first;
        }
        if (!Bluetooth.defaultAdapter)
            return "No Bluetooth";
        if (!root.btEnabled)
            return "Bluetooth off";
        return "No devices";
    }

    readonly property bool hasBattery: Services.Power.hasBattery
    readonly property real battLevel: Services.Power.level
    readonly property bool battCharging: Services.Power.charging
    readonly property int battPct: Services.Power.pct
    readonly property string battGlyph: {
        const p = root.battLevel * 100;
        if (root.battCharging)
            return "󰂄";
        if (p >= 90)
            return "󰁹";
        if (p >= 70)
            return "󰂂";
        if (p >= 50)
            return "󰁾";
        if (p >= 30)
            return "󰁼";
        if (p >= 10)
            return "󰁺";
        return "󰂎";
    }
    readonly property string battText: root.battPct + "%"
    readonly property int segCount: root.hasBattery ? 3 : 2

    readonly property real glyphW: 16
    readonly property real gap: 4
    readonly property real midGap: 12
    readonly property real sideMargins: 8
    readonly property real sideCap: Math.max(40, (parent.width - root.sideMargins - root.glyphW * root.segCount - root.gap * root.segCount - root.midGap * (root.segCount - 1)) / root.segCount)

    Row {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, parent.width - root.sideMargins)
        spacing: root.gap
        Text {
            visible: root.hasBattery
            anchors.verticalCenter: parent.verticalCenter
            width: root.hasBattery ? root.glyphW : 0
            horizontalAlignment: Text.AlignHCenter
            text: root.battGlyph
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px13
        }
        Text {
            visible: root.hasBattery
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: root.hasBattery ? Math.min(implicitWidth, root.sideCap) : 0
            text: root.battText
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px11
        }
        Item {
            visible: root.hasBattery
            width: root.hasBattery ? root.midGap : 0
            height: 1
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: root.glyphW
            horizontalAlignment: Text.AlignHCenter
            text: root.wifiGlyph
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
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
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: root.glyphW
            horizontalAlignment: Text.AlignHCenter
            text: root.btGlyph
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.sideCap)
            text: root.btText
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px11
        }
    }
}
