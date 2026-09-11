import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../Palette.js" as Palette

Text {

    required property var bar
    text: Bluetooth.defaultAdapter?.enabled
        ? "󰂯"
        : "󰂲"

    color:
        Bluetooth.defaultAdapter?.enabled
        ? Palette.fg
        : Palette.dim

    font.family: Palette.font
    font.pixelSize: Palette.px13

    MouseArea {
        anchors.fill: parent

        onClicked: bar.toggleControl()
    }
}