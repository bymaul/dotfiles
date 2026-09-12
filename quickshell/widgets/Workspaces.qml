import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../Palette.js" as Palette

Row {
    anchors {
        left: parent.left
        leftMargin: 10
        verticalCenter: parent.verticalCenter
    }

    spacing: 4

    Repeater {
        model: Hyprland.workspaces

        delegate: Item {
            required property var modelData

            width: 30
            height: 24

            Rectangle {
                anchors.fill: parent

                radius: 0

                color: modelData.focused
                    ? Palette.surface
                    : "transparent"
            }

            Text {
                anchors.centerIn: parent

                text: modelData.name || modelData.id

                color: modelData.focused
                    ? Palette.white
                    : Palette.dim

                font.family:
                    Palette.font

                font.pixelSize: Palette.px12
            }

            MouseArea {
                anchors.fill: parent

                onClicked: modelData.activate()
            }
        }
    }
}
