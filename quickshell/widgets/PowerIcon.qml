import QtQuick
import "../Palette.js" as Palette

Item {
    required property var bar

    anchors.verticalCenter: parent.verticalCenter

    width: powerText.width + 16
    height: 24

    Text {
        id: powerText

        anchors.centerIn: parent

        text: "󰐥"

        color: Palette.fg

        font.family: Palette.font
        font.pixelSize: Palette.px13
    }

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor

        onClicked: bar.togglePower()
    }
}
