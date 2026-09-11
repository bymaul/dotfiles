import QtQuick
import "../Palette.js" as Palette

Rectangle {
    id: tile

    required property string glyph
    required property string label
    required property bool active

    // Unavailable hardware (no mic, no bt adapter): rendered flat and
    // non-interactive instead of a silent dead-end.
    property bool enabled: true

    // Keyboard selection ring (control panel nav).
    property bool selected: false

    signal tileClicked

    width: (parent.width - 8) / 3
    height: 44
    radius: 0

    // Selection always wins visibly: an active+selected tile must
    // differ from active-only, otherwise keyboard focus disappears
    // on tiles that are already on.
    color: !tile.enabled ? Palette.onAccent
        : tile.selected ? Palette.surfaceHover
        : tile.active ? Palette.surface : Palette.onAccent
    border.width: tile.selected && tile.enabled ? 2 : 1
    border.color: tile.active && tile.enabled ? Palette.accent
        : tile.selected && tile.enabled ? Palette.fg : Palette.border
    opacity: tile.enabled ? 1 : 0.45

    Column {
        anchors.centerIn: parent

        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: tile.glyph

            color: !tile.enabled ? Palette.dim
                : tile.active ? Palette.accent
                : tile.selected ? Palette.fg : Palette.dim

            font.family: Palette.font
            font.pixelSize: Palette.px15
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: tile.label

            color: !tile.enabled ? Palette.dim
                : (tile.active || tile.selected) ? Palette.fg : Palette.dim

            font.family: Palette.font
            font.pixelSize: Palette.px10
        }
    }

    MouseArea {
        anchors.fill: parent

        enabled: tile.enabled
        hoverEnabled: true
        cursorShape: tile.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: tile.tileClicked()
    }
}