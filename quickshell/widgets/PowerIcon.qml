import QtQuick
import "../services" as Services
Item {
    required property var bar
    anchors.verticalCenter: parent.verticalCenter
    width: label.width + 16
    height: 24
    Text {
        id: label
        anchors.centerIn: parent
        text: "󰐥"
        color: Services.Theme.fg
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px13
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bar.togglePower()
    }
}
