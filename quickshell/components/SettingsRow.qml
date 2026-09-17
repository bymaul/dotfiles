import QtQuick
import "../Palette.js" as Palette

Rectangle {
    id: root
    required property string title
    property string value: ""
    property int titleWidth: 110
    property bool selected: false
    default property alias control: slot.data
    signal hovered
    width: parent.width
    height: Palette.rowHeight
    color: root.selected ? Palette.activeBg : Palette.surface
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: {
            if (containsMouse)
                root.hovered();
        }
    }
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
