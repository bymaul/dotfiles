import QtQuick
import Quickshell.Networking
import "../components"
import "../services" as Services
BarIcon {
    id: root
    required property var bar
    readonly property bool connected: Services.Wifi.connected != null
    readonly property bool wired: Services.Wifi.wiredConnected
    readonly property string wiredName: Services.Wifi.wiredDevice ? Services.Wifi.wiredDevice.name : ""
    readonly property real level: connected ? Number(Services.Wifi.connected.signalStrength ?? 0) || 0 : 0
    glyph: {
        if (root.wired)
            return "󰈀";
        if (!Networking.wifiEnabled)
            return "󰤭";
        if (!root.connected)
            return "󰤯";
        return Services.Wifi.signalGlyph(root.level);
    }
    glyphColor: (root.wired || (Networking.wifiEnabled && root.connected)) ? Services.Theme.fg : Services.Theme.dim
    tipText: {
        const lines = [];
        if (root.wired)
            lines.push("Wired: " + (root.wiredName !== "" ? root.wiredName : "connected"));
        if (!Networking.wifiEnabled)
            lines.push("Wi-Fi off");
        else if (Services.Wifi.connected)
            lines.push("Wi-Fi: " + Services.Wifi.connected.name);
        else
            lines.push("Wi-Fi: not connected");
        return lines.join("\n");
    }
    tipAnchor: root.bar
    onClicked: bar.toggleWifi()
}
