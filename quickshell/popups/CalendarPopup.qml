import QtQuick
import Quickshell
import "../components"
import "../services" as Services
BasePopup {
    id: root
    required property var clock
    anchorMode: "center"
    implicitWidth: Services.Theme.popupWidth
    implicitHeight: 256
    property date viewDate: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.stepMonth(-1) }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.stepMonth(1) }
    Shortcut { sequence: "Left"; enabled: root.visible; onActivated: root.stepMonth(-1) }
    Shortcut { sequence: "Right"; enabled: root.visible; onActivated: root.stepMonth(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepMonth(-12) }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepMonth(12) }
    Shortcut { sequence: "Up"; enabled: root.visible; onActivated: root.stepMonth(-12) }
    Shortcut { sequence: "Down"; enabled: root.visible; onActivated: root.stepMonth(12) }
    Shortcut { sequence: "t"; enabled: root.visible; onActivated: root.resetToToday() }
    onVisibleChanged: {
        if (visible)
            root.resetToToday();
    }
    function resetToToday(): void {
        root.viewDate = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1);
    }
    function stepMonth(offset: int): void {
        root.viewDate = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth() + offset, 1);
    }
    function daysInMonth(year: int, month: int): int {
        return new Date(year, month + 1, 0).getDate();
    }
    function weekStart(): int {
        return Qt.locale().firstDayOfWeek % 7;
    }
    function weekdayHeaders(): var {
        const names = ["S", "M", "T", "W", "T", "F", "S"];
        const start = root.weekStart();
        return names.slice(start).concat(names.slice(0, start));
    }
    function isToday(day: int): bool {
        return day === clock.date.getDate() && viewDate.getMonth() === clock.date.getMonth() && viewDate.getFullYear() === clock.date.getFullYear();
    }
    function dayCells(): var {
        const first = (viewDate.getDay() - root.weekStart() + 7) % 7;
        const total = root.daysInMonth(viewDate.getFullYear(), viewDate.getMonth());
        const cells = [];
        for (let i = 0; i < first; ++i)
            cells.push(0);
        for (let d = 1; d <= total; ++d)
            cells.push(d);
        while (cells.length < 42)
            cells.push(0);
        return cells;
    }
    PopupCard {
        Row {
            width: parent.width
            height: 26
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                horizontalAlignment: Text.AlignHCenter
                text: "󰅁"
                color: navLeft.containsMouse ? Services.Theme.fg : Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px14
                MouseArea {
                    id: navLeft
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.stepMonth(-1)
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 52
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(root.viewDate, "MMMM yyyy")
                color: Services.Theme.fg
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px13
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                horizontalAlignment: Text.AlignHCenter
                text: "󰅂"
                color: navRight.containsMouse ? Services.Theme.fg : Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px14
                MouseArea {
                    id: navRight
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.stepMonth(1)
                }
            }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px11
        }
        Row {
            width: parent.width
            height: 16
            Repeater {
                model: root.weekdayHeaders()
                Text {
                    required property string modelData
                    width: parent.width / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px11
                }
            }
        }
        Grid {
            width: parent.width
            height: 156
            columns: 7
            Repeater {
                model: root.dayCells()
                Rectangle {
                    required property var modelData
                    width: parent.width / 7
                    height: 26
                    color: modelData > 0 && root.isToday(modelData) ? Services.Theme.accent : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: modelData === 0 ? "" : modelData
                        color: modelData > 0 && root.isToday(modelData) ? Services.Theme.onAccent : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                    }
                }
            }
        }
    }
}
