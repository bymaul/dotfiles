import QtQuick
import "../Palette.js" as Palette

Rectangle {
    id: actionTile

    required property string glyph
    required property string label
    property string hint: ""

    // Keyboard selection (power menu nav). Selected is one step
    // brighter than hover: surfaceHover bg + fg border.
    property bool selected: false

    signal actionClicked

    width: (parent.width - 8) / 2
    height: 46
    radius: 0

    readonly property bool highlighted:
        tileHover.containsMouse || actionTile.selected

    color: actionTile.selected ? Palette.surfaceHover
        : tileHover.containsMouse ? Palette.surface : Palette.onAccent
    border.width: 1
    border.color: actionTile.selected ? Palette.fg : Palette.border

    Column {
        anchors.centerIn: parent

        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: actionTile.glyph

            color: actionTile.highlighted
                ? Palette.accent
                : Palette.fg

            font.family: Palette.font
            font.pixelSize: Palette.px16
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: actionTile.hint !== ""
                ? actionTile.label + " [" + actionTile.hint + "]"
                : actionTile.label

            color: actionTile.highlighted
                ? Palette.fg
                : Palette.dim

            font.family: Palette.font
            font.pixelSize: Palette.px11
        }
    }

    MouseArea {
        id: tileHover

        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: actionTile.actionClicked()
    }
}