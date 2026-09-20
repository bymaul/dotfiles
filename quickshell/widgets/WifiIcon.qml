import QtQuick
import Quickshell.Networking
import "../components"
import "../services" as Services
BarIcon {
    id: root
    required property var bar
    readonly property bool connected: Services.Wifi.connected != null
    readonly property real level: connected ? Number(Services.Wifi.connected.signalStrength ?? 0) || 0 : 0
    glyph: {
        if (!Networking.wifiEnabled)
            return "󰤭";
        if (!root.connected)
            return "󰤯";
        return Services.Wifi.signalGlyph(root.level);
    }
    glyphColor: (!Networking.wifiEnabled || !root.connected) ? Services.Theme.dim : Services.Theme.fg
    onClicked: bar.toggleControl()
}
