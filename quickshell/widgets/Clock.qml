import QtQuick
import "../Palette.js" as Palette
Item {
    required property var bar
    required property var clockSource
    anchors.centerIn: parent
    width: label.width + 20
    height: Palette.barHeight
    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clockSource.date, "HH:mm")
        color: Palette.fg
        font.family: Palette.font
        font.pixelSize: Palette.px13
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bar.toggleCalendar()
    }
}
