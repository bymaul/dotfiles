import QtQuick
import "../components"
import "../services" as Services
BarIcon {
    id: root
    required property var bar
    anchors.verticalCenter: parent.verticalCenter
    readonly property bool hasUnread: Services.Notifs.unread > 0
    glyph: ""
    glyphColor: root.hasUnread ? Services.Theme.accent : Services.Theme.dim
    tipText: "Notifications"
    tipAnchor: bar
    onClicked: bar.toggleControl()
    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: -2
            rightMargin: -3
        }
        width: 8
        height: 8
        radius: 4
        visible: root.hasUnread
        color: Services.Theme.accent
        border.color: Services.Theme.barBg
        border.width: 1
        z: 1
    }
}
