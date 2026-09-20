import QtQuick
import "../services" as Services
Item {
    id: root
    required property var bar
    anchors.verticalCenter: parent.verticalCenter
    width: 20
    height: 20
    readonly property bool hasUnread: Services.Notifs.unread > 0
    Text {
        anchors.centerIn: parent
        text: ""
        color: root.hasUnread ? Services.Theme.accent : Services.Theme.dim
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px13
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
        radius: 3.5
        visible: root.hasUnread
        color: Services.Theme.accent
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.bar.toggleControl()
    }
}
