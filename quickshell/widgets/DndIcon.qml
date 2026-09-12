import QtQuick
import "../services" as Services
import "../Palette.js" as Palette

Item {
    visible: Services.Modes.dndActive

    width: dndText.width
    height: dndText.height

    Text {
        id: dndText

        text: ""

        color: Palette.fg

        font.family: Palette.font
        font.pixelSize: Palette.px13

        MouseArea {
            anchors.fill: parent

            cursorShape: Qt.PointingHandCursor

            onClicked: Services.Modes.toggleDnd()
        }
    }
}
