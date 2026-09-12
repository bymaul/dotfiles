import QtQuick
import Quickshell
import Quickshell.Io
import "../Palette.js" as Palette

Item {
    id: memCpu

    required property var bar

    width: memCpuRow.width
    height: memCpuRow.height

    Row {
        id: memCpuRow

        spacing: 12

        Text {
            text: memCpu.bar.memUsed > 0
                ? " " + memCpu.bar.memUsed.toFixed(1) + "G"
                : " --G"

            color: Palette.fg

            font.family: Palette.font
            font.pixelSize: Palette.px13
        }

        // ====================================================
        // CPU
        // ====================================================

        Text {
            text: "󰍛 " + memCpu.bar.cpuUsage + "%"

            color: Palette.fg

            font.family: Palette.font
            font.pixelSize: Palette.px13
        }
    }

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor

        onClicked: btop.running = true
    }

    Process {
        id: btop

        command: [
            "kitty", "--class", "btop", "btop"
        ]

        running: false

        onExited: btop.running = false
    }
}