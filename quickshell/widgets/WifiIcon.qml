import QtQuick
import Quickshell.Networking
import "../components"
import "../Palette.js" as Palette
Item {
    required property var bar
    implicitWidth: icon.width
    implicitHeight: icon.height
    width: icon.width
    height: icon.height
    readonly property bool connected: bar.connectedWifi != null
    readonly property real level: connected ? Number(bar.connectedWifi.signalStrength ?? 0) || 0 : 0
    BarIcon {
        id: icon
        glyph: {
            if (!Networking.wifiEnabled)
                return "󰤭";
            if (!parent.connected)
                return "󰤯";
            if (parent.level >= Palette.sigHigh)
                return "󰤨";
            if (parent.level >= Palette.sigMed)
                return "󰤥";
            if (parent.level >= Palette.sigLow)
                return "󰤢";
            return "󰤟";
        }
        glyphColor: (!Networking.wifiEnabled || !parent.connected) ? Palette.dim : Palette.fg
        onClicked: bar.toggleControl()
    }
}
