import QtQuick
import "../services" as Services
import "../Palette.js" as Palette

Item {
    id: bell

    required property var bar

    anchors.verticalCenter: parent.verticalCenter

    width: 20
    height: 20

    Text {
        anchors.centerIn: parent

        text: ""

        color: Services.Notifs.unread > 0 ? Palette.accent : Palette.dim

        font.family: Palette.font
        font.pixelSize: Palette.px13
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 2
            rightMargin: 1
        }

        width: 7
        height: 7

        radius: 4

        visible: Services.Notifs.unread > 0

        color: Palette.accent
    }

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor

        onClicked: bell.bar.toggleControl()
    }
}
