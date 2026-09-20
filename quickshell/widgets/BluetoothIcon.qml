import QtQuick
import Quickshell.Bluetooth
import "../components"
import "../services" as Services
BarIcon {
    required property var bar
    glyph: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
    glyphColor: Bluetooth.defaultAdapter?.enabled ? Services.Theme.fg : Services.Theme.dim
    onClicked: bar.toggleControl()
}
