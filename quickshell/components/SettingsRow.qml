import QtQuick
import "../Palette.js" as Palette

// Label on the left, control slotted on the right.
Rectangle {
    id: root
    required property string title
    property string value: ""
    property int titleWidth: 110
    property bool selected: false
    default property alias control: slot.data
    width: parent.width
    height: Palette.rowHeight
    color: Palette.surface
    border.width: root.selected ? 1 : 0
    border.color: root.selected ? Palette.accent : Palette.dim
    Text {
        anchors {
            left: parent.left
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
        width: root.titleWidth
        text: root.title
        color: Palette.fg
        font.family: Palette.font
        font.pixelSize: Palette.px12
        elide: Text.ElideRight
    }
    Item {
        id: slot
        anchors {
            left: parent.left
            leftMargin: 10 + root.titleWidth + 14
            right: parent.right
            rightMargin: root.value !== "" ? 48 : 10
            verticalCenter: parent.verticalCenter
        }
        height: parent.height
    }
    Text {
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        visible: root.value !== ""
        text: root.value
        color: Palette.dim
        font.family: Palette.font
        font.pixelSize: Palette.px12
    }
}
