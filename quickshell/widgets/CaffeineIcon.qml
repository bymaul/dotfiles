import QtQuick
import "../services" as Services
import "../Palette.js" as Palette

Item {
    id: caffeineIcon

    visible: Services.Modes.caffeineActive

    width: caffeineText.width
    height: caffeineText.height

    Text {
        id: caffeineText

        text: ""

        color: Palette.fg

        font.family: Palette.font
        font.pixelSize: Palette.px13

        MouseArea {
            anchors.fill: parent

            cursorShape: Qt.PointingHandCursor

            onClicked: Services.Modes.toggleCaffeine()
        }
    }
}
