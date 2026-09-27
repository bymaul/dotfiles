import QtQuick
import Quickshell
import Quickshell.Io
import "../services" as Services
Item {
    id: root
    required property var bar
    implicitWidth: row.width
    implicitHeight: row.height
    width: row.width
    height: row.height
    Row {
        id: row
        spacing: Services.Theme.groupSpacing
        Text {
            text: Services.Perf.memUsed > 0 ? " " + Services.Perf.memUsed.toFixed(1) + "G" : " --G"
            color: Services.Theme.fg
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px13
        }
        Text {
            text: "󰍛 " + Services.Perf.cpuUsage + "%"
            color: Services.Theme.fg
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px13
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!btop.running) {
                const term = Quickshell.env("TERMINAL") ?? "kitty";
                btop.command = term === "kitty" ? ["kitty", "--class", "btop", "btop"] : [term, "-e", "btop"];
                btop.running = true;
            }
        }
    }
    Process {
        id: btop
        command: ["kitty", "--class", "btop", "btop"]
        running: false
        onExited: btop.running = false
    }
}
