import QtQuick
import "../components"
import "../services" as Services
BarIcon {
    id: root
    required property var bar
    readonly property bool connected: Services.Wifi.connected != null
    readonly property var connectingNet: Services.Wifi.connecting
    readonly property bool wired: Services.Wifi.wiredConnected
    readonly property string wiredName: Services.Wifi.wiredDevice?.name ?? ""
    readonly property bool hwBlocked: !Services.Wifi.hardwareEnabled
    readonly property bool swOff: !Services.Wifi.enabled
    readonly property real level: connected ? Services.Wifi.signalLevel(Services.Wifi.connected?.signalStrength) : 0
    glyph: {
        if (root.wired)
            return "󰈀";
        if (root.hwBlocked)
            return "󰤭";
        if (root.swOff)
            return "󰤭";
        if (root.connectingNet)
            return "󰤭";
        if (!root.connected)
            return "󰤯";
        return Services.Wifi.signalGlyph(root.level);
    }
    glyphColor: (root.wired || (!root.swOff && !root.hwBlocked && root.connected)) ? Services.Theme.fg : Services.Theme.dim
    tipText: {
        const lines = [];
        if (root.wired)
            lines.push("Wired: " + (root.wiredName !== "" ? root.wiredName : "connected"));
        if (root.hwBlocked)
            lines.push("Wi-Fi blocked (rfkill)");
        else if (root.swOff)
            lines.push("Wi-Fi off");
        else if (Services.Wifi.connected)
            lines.push("Wi-Fi: " + (Services.Wifi.connected?.name ?? "connected"));
        else if (root.connectingNet)
            lines.push("Wi-Fi connecting: " + (root.connectingNet?.name ?? "…"));
        else
            lines.push("Wi-Fi: not connected");
        return lines.join("\n");
    }
    tipAnchor: root.bar
    onClicked: bar.togglePopup("wifi")
}
