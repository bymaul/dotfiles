import QtQuick
import Quickshell
import "../Palette.js" as Palette

PopupWindow {
    id: calendar

    required property var bar
    required property var clock

    anchor.window: bar

    anchor.rect.x:
        bar.width / 2 - width / 2

    anchor.rect.y:
        bar.height + Palette.popupTopGap

    implicitWidth: Palette.popupWidth
    implicitHeight: 268

    visible: false

    color: "transparent"

    grabFocus: true

    Shortcut {
        sequence: "Escape"
        onActivated: bar.closePopups()
    }

    Shortcut {
        sequence: "Left"
        enabled: calendar.visible
        onActivated: calendarFrame.stepMonth(-1)
    }

    Shortcut {
        sequence: "Right"
        enabled: calendar.visible
        onActivated: calendarFrame.stepMonth(1)
    }

    Shortcut {
        sequence: "t"
        enabled: calendar.visible
        onActivated: calendarFrame.resetToToday()
    }

    onVisibleChanged: {
        if (visible)
            calendarFrame.resetToToday()
    }

    Rectangle {
        id: calendarFrame

        anchors.fill: parent

        radius: 0

        color: Palette.bg

        border.width: 1
        border.color: Palette.border

        property date viewDate: new Date(
            clock.date.getFullYear(),
            clock.date.getMonth(),
            1
        )

        function resetToToday(): void {
            calendarFrame.viewDate = new Date(
                clock.date.getFullYear(),
                clock.date.getMonth(),
                1
            )
        }

        function stepMonth(offset: int): void {
            calendarFrame.viewDate = new Date(
                calendarFrame.viewDate.getFullYear(),
                calendarFrame.viewDate.getMonth() + offset,
                1
            )
        }

        function daysInMonth(year: int, month: int): int {
            return new Date(year, month + 1, 0).getDate()
        }

        // Qt day-of-week is 1 = Monday .. 7 = Sunday; JS getDay() is
        // 0 = Sunday. The grid follows the system locale's first day.
        function weekStart(): int {
            return Qt.locale().firstDayOfWeek % 7
        }

        function weekdayHeaders(): var {
            const names = ["S", "M", "T", "W", "T", "F", "S"]
            const start = calendarFrame.weekStart()

            return names.slice(start).concat(names.slice(0, start))
        }

        function isToday(day: int): bool {
            return day === clock.date.getDate()
                && viewDate.getMonth() === clock.date.getMonth()
                && viewDate.getFullYear() === clock.date.getFullYear()
        }

        function dayCells(): var {
            const first = (viewDate.getDay() - calendarFrame.weekStart() + 7) % 7
            const total = daysInMonth(
                viewDate.getFullYear(), viewDate.getMonth()
            )
            const cells = []

            for (let i = 0; i < first; ++i)
                cells.push({ day: 0, other: true })

            for (let d = 1; d <= total; ++d)
                cells.push({ day: d, other: false })

            while (cells.length < 42)
                cells.push({ day: 0, other: true })

            return cells
        }

        Column {
            anchors {
                fill: parent
                margins: 12
            }

            spacing: 8

            // MONTH NAVIGATION
            Row {
                width: parent.width
                height: 26

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    width: 26

                    horizontalAlignment: Text.AlignHCenter

                    text: "󰅁"

                    color: navLeftHover.containsMouse
                        ? Palette.fg
                        : Palette.dim

                    font.family: Palette.font
                    font.pixelSize: Palette.px18

                    MouseArea {
                        id: navLeftHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            calendarFrame.stepMonth(-1)
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    width: parent.width - 52

                    horizontalAlignment: Text.AlignHCenter

                    text: Qt.formatDateTime(
                        calendarFrame.viewDate,
                        "MMMM yyyy"
                    )

                    color: Palette.fg

                    font.family: Palette.font
                    font.pixelSize: Palette.px16
                    font.bold: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    width: 26

                    horizontalAlignment: Text.AlignHCenter

                    text: "󰅂"

                    color: navRightHover.containsMouse
                        ? Palette.fg
                        : Palette.dim

                    font.family: Palette.font
                    font.pixelSize: Palette.px18

                    MouseArea {
                        id: navRightHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            calendarFrame.stepMonth(1)
                        }
                    }
                }
            }

            // FULL DATE
            Text {
                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                text: Qt.formatDateTime(
                    clock.date,
                    "dddd, dd MMMM yyyy"
                )

                color: Palette.accent

                font.family: Palette.font
                font.pixelSize: Palette.px13
            }

            // WEEKDAY HEADERS
            Row {
                width: parent.width
                height: 16

                // Rotated to the locale's first weekday (see weekStart).
                Repeater {
                    model: calendarFrame.weekdayHeaders()

                    Text {
                        required property string modelData

                        width: parent.width / 7

                        horizontalAlignment: Text.AlignHCenter

                        text: modelData

                        color: Palette.dim

                        font.family: Palette.font
                        font.pixelSize: Palette.px11
                    }
                }
            }

            // DAY GRID
            Grid {
                width: parent.width
                height: 156

                columns: 7

                Repeater {
                    model: calendarFrame.dayCells()

                    Rectangle {
                        required property var modelData

                        width: parent.width / 7
                        height: 26

                        color: modelData.day > 0 &&
                            calendarFrame.isToday(modelData.day)
                            ? Palette.accent
                            : "transparent"

                        // Display-only cells: no hover or click affordance.
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }

                        Text {
                            anchors.centerIn: parent

                            text: modelData.day === 0
                                ? ""
                                : modelData.day

                            color: modelData.day > 0 &&
                                calendarFrame.isToday(modelData.day)
                                ? Palette.onAccent
                                : Palette.fg

                            font.family:
                                Palette.font
                            font.pixelSize: Palette.px12
                        }
                    }
                }
            }
        }
    }
}