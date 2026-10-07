import QtQuick
import Quickshell
import Quickshell.Io
import "../services" as Services
Item {
    id: root
    required property var bar
    property int hPadding: Services.Theme.barIconPadding
    property bool tipHover: false
    implicitWidth: row.width + hPadding * 2
    implicitHeight: row.height
    width: implicitWidth
    height: row.height
    function fmtTemp(v: real): string {
        if (!isFinite(v) || v < 0)
            return "--";
        return v.toFixed(1) + "°C";
    }
    function fmtFan(v: int): string {
        if (!isFinite(v) || v < 0)
            return "--";
        return v + " RPM";
    }
    function showTip(): void {
        if (!root.tipHover || !root.bar)
            return;
        const target = root.bar.contentItem;
        if (!target)
            return;
        const pt = root.mapToItem(target, 0, root.height);
        tip.anchor.rect.x = Math.max(Services.Theme.popupMargin, pt.x + root.width / 2 - tip.width / 2);
        tip.anchor.rect.y = pt.y + 4;
        tip.visible = true;
    }
    function hideTip(): void {
        root.tipHover = false;
        tipTimer.stop();
        tip.visible = false;
    }
    function armTip(): void {
        root.tipHover = true;
        tipTimer.restart();
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: Services.Theme.tightSpacing
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
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.armTip()
        onExited: root.hideTip()
        onClicked: {
            root.hideTip();
            if (!btop.running) {
                const term = Quickshell.env("TERMINAL") ?? "kitty";
                btop.command = term === "kitty" ? ["kitty", "--class", "btop", "btop"] : [term, "-e", "btop"];
                btop.running = true;
            }
        }
    }
    Timer {
        id: tipTimer
        interval: 400
        repeat: false
        onTriggered: root.showTip()
    }
    PopupWindow {
        id: tip
        visible: false
        grabFocus: false
        anchor.window: root.bar
        implicitWidth: tipCol.implicitWidth + 16
        implicitHeight: tipCol.implicitHeight + 12
        Rectangle {
            anchors.fill: parent
            color: Services.Theme.bg
            border.width: 1
            border.color: Services.Theme.border
            Column {
                id: tipCol
                anchors.centerIn: parent
                spacing: 2
                Text {
                    text: "CPU  " + Services.Perf.cpuUsage + "% · " + root.fmtTemp(Services.Perf.cpuTemp)
                    color: Services.Theme.fg
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px11
                }
                Text {
                    text: Services.Perf.memTotal > 0 ? "MEM  " + Services.Perf.memUsed.toFixed(1) + " / " + Services.Perf.memTotal.toFixed(1) + "G (" + Services.Perf.memPct + "%)" : "MEM  --"
                    color: Services.Theme.fg
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px11
                }
                Text {
                    text: "GPU  " + root.fmtTemp(Services.Perf.gpuTemp)
                    color: Services.Theme.fg
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px11
                }
                Text {
                    text: "FAN  CPU " + root.fmtFan(Services.Perf.cpuFan) + " · GPU " + root.fmtFan(Services.Perf.gpuFan)
                    color: Services.Theme.fg
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px11
                }
                Text {
                    visible: Services.Asus.available
                    text: "Profile  " + Services.Asus.profileLabel
                    color: Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px11
                }
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
