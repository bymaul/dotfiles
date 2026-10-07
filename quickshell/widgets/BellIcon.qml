import QtQuick
import "../components"
import "../services" as Services
BarIcon {
    id: root
    required property var bar
    anchors.verticalCenter: parent.verticalCenter
    readonly property bool hasUnread: Services.Notifs.unread > 0
    readonly property bool dnd: Services.Modes.dndActive
    glyph: root.dnd ? "" : ""
    glyphColor: root.dnd ? Services.Theme.danger : root.hasUnread ? Services.Theme.accent : Services.Theme.dim
    tipText: root.dnd ? "Do not disturb" : "Notifications"
    tipAnchor: bar
    onClicked: bar.togglePopup("control")
    implicitWidth: Math.max(bellRef.implicitWidth, slashRef.implicitWidth) + root.hPadding * 2
    Text {
        id: bellRef
        visible: false
        text: ""
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px13
    }
    Text {
        id: slashRef
        visible: false
        text: ""
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px13
    }
    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: -1
            rightMargin: -1
        }
        width: 8
        height: 8
        radius: 4
        visible: !root.dnd && root.hasUnread
        color: root.dnd ? Services.Theme.danger : Services.Theme.accent
        border.color: Services.Theme.barBg
        border.width: 1
        z: 1
    }
}
