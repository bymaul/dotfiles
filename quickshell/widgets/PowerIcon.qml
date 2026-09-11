import QtQuick
import "../Palette.js" as Palette

Text {

    required property var bar
    text: "󰐥"

    color: Palette.fg

    font.family: Palette.font
    font.pixelSize: Palette.px13

    MouseArea {
        anchors.fill: parent

        onClicked: bar.togglePower()
    }
}