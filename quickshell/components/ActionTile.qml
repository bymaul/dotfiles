import QtQuick
import "../Palette.js" as Palette

Rectangle {
    id: actionTile

    required property string glyph
    required property string label

    signal actionClicked

    width: (parent.width - 8) / 2
    height: 40
    radius: 0

    readonly property bool highlighted:
        tileHover.containsMouse

    color: tileHover.containsMouse ? Palette.hoverBg : Palette.surface
    border.width: 0

    Column {
        anchors.centerIn: parent

        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: actionTile.glyph

            color: actionTile.highlighted ? Palette.accent : Palette.dim

            font.family: Palette.font
            font.pixelSize: Palette.px14
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: actionTile.label

            color: actionTile.highlighted ? Palette.fg : Palette.dim

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