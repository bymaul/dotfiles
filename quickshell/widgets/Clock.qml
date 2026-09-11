import QtQuick
import "../Palette.js" as Palette

Text {
    id: clock

    required property var bar
    required property var clockSource

    anchors.centerIn: parent

    text: {
        const d = clockSource ? clockSource.date : null

        return d ? Qt.formatDateTime(d, "HH:mm") : ""
    }

    color: Palette.fg

    font.family: Palette.font
    font.pixelSize: Palette.px13

    MouseArea {
        anchors.fill: parent

        onClicked: {
            bar.toggleCalendar()
        }
    }
}