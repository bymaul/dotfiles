import QtQuick
import Quickshell
import "../components"
import "../services" as Services
BasePopup {
    id: root
    required property var clock
    anchorMode: "right"
    implicitWidth: Services.Theme.popupWidth
    implicitHeight: 256
    property date viewDate: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
    property int selectedDay: clock.date.getDate()
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.moveSelection(-1) }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.moveSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.moveSelection(-7) }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.moveSelection(7) }
    Shortcut { sequence: "Left"; enabled: root.visible; onActivated: root.moveSelection(-1) }
    Shortcut { sequence: "Right"; enabled: root.visible; onActivated: root.moveSelection(1) }
    Shortcut { sequence: "Up"; enabled: root.visible; onActivated: root.moveSelection(-7) }
    Shortcut { sequence: "Down"; enabled: root.visible; onActivated: root.moveSelection(7) }
    Shortcut { sequence: "Shift+H"; enabled: root.visible; onActivated: root.stepMonth(-1) }
    Shortcut { sequence: "Shift+L"; enabled: root.visible; onActivated: root.stepMonth(1) }
    Shortcut { sequence: "Shift+K"; enabled: root.visible; onActivated: root.stepMonth(-12) }
    Shortcut { sequence: "Shift+J"; enabled: root.visible; onActivated: root.stepMonth(12) }
    Shortcut { sequence: "Shift+Left"; enabled: root.visible; onActivated: root.stepMonth(-1) }
    Shortcut { sequence: "Shift+Right"; enabled: root.visible; onActivated: root.stepMonth(1) }
    Shortcut { sequence: "Shift+Up"; enabled: root.visible; onActivated: root.stepMonth(-12) }
    Shortcut { sequence: "Shift+Down"; enabled: root.visible; onActivated: root.stepMonth(12) }
    Shortcut { sequence: "t"; enabled: root.visible; onActivated: root.resetToToday() }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.openSelected() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.openSelected() }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.openSelected() }
    onVisibleChanged: {
        if (visible)
            root.resetToToday();
    }
    function resetToToday(): void {
        root.viewDate = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1);
        root.selectedDay = clock.date.getDate();
    }
    function stepMonth(offset: int): void {
        root.viewDate = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth() + offset, 1);
        root.clampSelection();
    }
    function clampSelection(): void {
        const max = root.daysInMonth(root.viewDate.getFullYear(), root.viewDate.getMonth());
        root.selectedDay = Math.max(1, Math.min(root.selectedDay, max));
    }
    function moveSelection(delta: int): void {
        const d = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth(), root.selectedDay + delta);
        root.viewDate = new Date(d.getFullYear(), d.getMonth(), 1);
        root.selectedDay = d.getDate();
    }
    function openSelected(): void {
        root.openCalendar(root.selectedDay);
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
    function openCalendar(day: int): void {
        if (day <= 0) return;
        const year = root.viewDate.getFullYear();
        const month = root.viewDate.getMonth() + 1;
        Qt.openUrlExternally(`https://calendar.google.com/calendar/u/0/r/day/${year}/${month}/${day}`);
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
                    readonly property bool isTodayCell: modelData > 0 && root.isToday(modelData)
                    readonly property bool isSelectedCell: modelData > 0 && modelData === root.selectedDay
                    width: parent.width / 7
                    height: 26
                    color: isSelectedCell ? Services.Theme.accent : isTodayCell ? Services.Theme.activeBg : Services.Theme.transparent
                    Text {
                        anchors.centerIn: parent
                        text: modelData === 0 ? "" : modelData
                        color: parent.isSelectedCell ? Services.Theme.accentFg : parent.isTodayCell ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.modelData > 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedDay = parent.modelData
                        onClicked: root.openCalendar(parent.modelData)
                    }
                }
            }
        }
    }
}
