import QtQuick
import Quickshell.Bluetooth
import "../components"
import "../Palette.js" as Palette
Item {
    required property var bar
    implicitWidth: icon.width
    implicitHeight: icon.height
    width: icon.width
    height: icon.height
    BarIcon {
        id: icon
        glyph: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
        glyphColor: Bluetooth.defaultAdapter?.enabled ? Palette.fg : Palette.dim
        onClicked: bar.toggleControl()
    }
}
