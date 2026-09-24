import QtQuick
import "../services" as Services
Item {
    required property var bar
    required property var clockSource
    anchors.verticalCenter: parent.verticalCenter
    width: label.width
    height: label.height
    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clockSource.date, "HH:mm")
        color: Services.Theme.fg
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px13
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bar.toggleCalendar()
    }
}
