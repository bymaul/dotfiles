import QtQuick
import "../Palette.js" as Palette
Rectangle {
    id: root
    required property string label
    property bool selected: false
    property bool accent: false
    property int columns: 2
    signal clicked
    // N buttons share the row exactly: total = columns * width + (columns - 1) * spacing.
    width: (parent.width - (columns - 1) * Palette.popupSpacing) / columns
    height: Palette.rowHeight
    color: root.accent ? Palette.accent : hover.containsMouse ? Palette.hoverBg : Palette.surface
    border.width: root.selected ? 1 : 0
    border.color: root.accent ? (root.selected ? Palette.fg : Palette.accent) : Palette.fg
    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.accent ? Palette.onAccent : Palette.fg
        font.family: Palette.font
        font.pixelSize: Palette.px12
    }
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
