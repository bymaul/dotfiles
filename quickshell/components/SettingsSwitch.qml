import QtQuick
import "../Palette.js" as Palette

Item {
    id: root
    required property bool on
    property bool disabled: false
    signal toggled
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: 44
    height: 24
    opacity: root.disabled ? 0.45 : 1
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 22
        radius: 11
        color: root.on ? Palette.accent : Palette.hoverBg
        border.width: 1
        border.color: root.on ? Palette.accent : Palette.dim
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: root.on ? 24 : 2
            width: 18
            height: 18
            radius: 9
            color: root.on ? Palette.onAccent : Palette.dim
        }
        MouseArea {
            anchors.fill: parent
            enabled: !root.disabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }
}
