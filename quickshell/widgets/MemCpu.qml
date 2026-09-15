import QtQuick
import Quickshell.Io
import "../services" as Services
import "../Palette.js" as Palette
Item {
    id: root
    required property var bar
    implicitWidth: row.width
    implicitHeight: row.height
    width: row.width
    height: row.height
    Row {
        id: row
        spacing: Palette.groupSpacing
        Text {
            text: Services.Perf.memUsed > 0 ? " " + Services.Perf.memUsed.toFixed(1) + "G" : " --G"
            color: Palette.fg
            font.family: Palette.font
            font.pixelSize: Palette.px13
        }
        Text {
            text: "󰍛 " + Services.Perf.cpuUsage + "%"
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
        command: ["kitty", "--class", "btop", "btop"]
        running: false
        onExited: btop.running = false
    }
}
