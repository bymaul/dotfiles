import QtQuick
import "../Palette.js" as Palette

Rectangle {
    id: tile

    required property string glyph
    required property string label
    required property bool active

    property bool enabled: true

    property bool selected: false

    signal tileClicked

    width: (parent.width - 8) / 3
    height: 40
    radius: 0

    color: !tile.enabled ? "transparent" : tile.selected ? Palette.accent : tile.active ? Palette.activeBg : tileHover.containsMouse ? Palette.hoverBg : Palette.surface
    border.width: tile.selected ? 1 : 0
    border.color: Palette.accent
    opacity: tile.enabled ? 1 : 0.45

    Column {
        anchors.centerIn: parent

        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: tile.glyph

            color: !tile.enabled ? Palette.dim : tile.selected ? Palette.onAccent : tile.active ? Palette.accent : tileHover.containsMouse ? Palette.fg : Palette.dim

            font.family: Palette.font
            font.pixelSize: Palette.px14
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: tile.label

            color: !tile.enabled ? Palette.dim : tile.selected ? Palette.onAccent : (tile.active || tileHover.containsMouse) ? Palette.fg : Palette.dim

            font.family: Palette.font
            font.pixelSize: Palette.px10
        }
    }

    MouseArea {
        id: tileHover

        anchors.fill: parent

        enabled: tile.enabled
        hoverEnabled: true
        cursorShape: tile.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: tile.tileClicked()
    }
}
