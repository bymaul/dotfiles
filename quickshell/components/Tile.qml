import QtQuick
import "../Palette.js" as Palette
Rectangle {
    id: root
    required property string glyph
    required property string label
    property bool active: false
    property bool available: true
    property bool selected: false
    property bool accentButton: false
    property bool wide: false
    property int columns: 3
    signal clicked
    signal hovered
    width: root.wide ? parent.width : (parent.width - 8) / columns
    height: Palette.tileHeight
    color: !root.available ? "transparent" : root.accentButton ? Palette.accent : root.selected ? Palette.accent : root.active ? Palette.activeBg : hover.containsMouse ? Palette.hoverBg : Palette.surface
    opacity: root.available ? 1 : 0.45
    Column {
        anchors.centerIn: parent
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.glyph
            color: !root.available ? Palette.dim : root.accentButton ? Palette.onAccent : root.selected ? Palette.onAccent : root.active ? Palette.accent : hover.containsMouse ? Palette.fg : Palette.dim
            font.family: Palette.font
            font.pixelSize: Palette.px14
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: !root.available ? Palette.dim : root.accentButton ? Palette.onAccent : root.selected ? Palette.onAccent : (root.active || hover.containsMouse) ? Palette.fg : Palette.dim
            font.family: Palette.font
            font.pixelSize: Palette.px10
        }
    }
    MouseArea {
        id: hover
        anchors.fill: parent
        enabled: root.available
        hoverEnabled: true
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
        onContainsMouseChanged: {
            if (containsMouse)
                root.hovered();
        }
    }
}
