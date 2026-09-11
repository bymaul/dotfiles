import QtQuick
import Quickshell
import "../services" as Services
import "../Palette.js" as Palette

// Companion to the control panel: a thin header bar plus one
// independent floating card per notification, anchored beneath the
// panel and shown/hidden with it. No outer container: every box
// floats on its own, exactly like toasts. Click a card to dismiss.
//
// No focus grab of its own: the bar-level grab whitelists BOTH this
// window and the panel, so clicks here never read as outside clicks.
//
// Keyboard: the panel owns selectedIndex and all nav logic, but keys
// reach only the focused window. This window carries a mirror
// shortcut set delegating to the panel, so nav works from either.
PopupWindow {
    id: historyPanel

    required property var bar
    required property var panel

    anchor.window: bar

    anchor.rect.x: bar.width - width - Palette.popupMargin
    anchor.rect.y: bar.height + Palette.popupTopGap + panel.height + 8

    implicitWidth: Palette.popupWidth

    // Header bar 34 + spacing + scrollable cards, capped at half
    // the screen. Header only when empty.
    readonly property int listCap: Math.max(96,
        Math.round(Screen.height / 2) - 34 - 8)

    implicitHeight: 34 + (Services.Notifs.history.length > 0
        ? 8 + Math.min(historyPanel.listCap, histList.contentHeight)
        : 0)

    visible: panel.visible

    color: "transparent"

    function revealAt(i: int): void {
        histList.positionViewAtIndex(i, ListView.Contain)
    }

    // Unguarded like the panel's own Escape: whichever window holds
    // focus, Esc closes everything.
    Shortcut {
        sequence: "Escape"
        onActivated: bar.closePopups()
    }

    // Mirror of the panel's nav set (delegating to it): key events
    // reach only the focused window, so the sets can't double-fire.
    Shortcut {
        sequence: "Down"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.stepVertical(1)
    }
    Shortcut {
        sequence: "j"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.stepVertical(1)
    }
    Shortcut {
        sequence: "Up"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.stepVertical(-1)
    }
    Shortcut {
        sequence: "k"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.stepVertical(-1)
    }
    Shortcut {
        sequence: "Left"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.adjustSelected(-1)
    }
    Shortcut {
        sequence: "h"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.adjustSelected(-1)
    }
    Shortcut {
        sequence: "Right"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.adjustSelected(1)
    }
    Shortcut {
        sequence: "l"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.adjustSelected(1)
    }
    Shortcut {
        sequence: "Return"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.activateSelected()
    }
    Shortcut {
        sequence: "Enter"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.activateSelected()
    }
    Shortcut {
        sequence: "Space"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.activateSelected()
    }
    Shortcut {
        sequence: "m"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.toggleVolumeMute()
    }

    Column {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        spacing: 8

        // THIN HEADER BAR (clear + unread badge live here)
        Rectangle {
            width: parent.width
            height: 34

            radius: 0

            color: Palette.bg

            border.width: 1
            border.color: Palette.border

            Row {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    width: parent.width - 130 -
                        (Services.Notifs.unread > 0 ? 50 : 0)

                    text: "Notifications (" +
                        Services.Notifs.history.length + ")"

                    color: Palette.fg

                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                    font.bold: true

                    elide: Text.ElideRight
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    width: Services.Notifs.unread > 0 ? 50 : 0

                    horizontalAlignment: Text.AlignRight

                    visible: Services.Notifs.unread > 0

                    text: Services.Notifs.unread + " new"

                    color: Palette.accent

                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    width: 70

                    horizontalAlignment: Text.AlignRight

                    text: "Mark read"

                    color: markReadHover.containsMouse
                        ? Palette.fg : Palette.dim

                    font.family: Palette.font
                    font.pixelSize: Palette.px12

                    MouseArea {
                        id: markReadHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Services.Notifs.markRead()
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    width: 60

                    horizontalAlignment: Text.AlignRight

                    text: "Clear"

                    color: clearHover.containsMouse
                        ? Palette.fg : Palette.dim

                    font.family: Palette.font
                    font.pixelSize: Palette.px12

                    MouseArea {
                        id: clearHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Services.Notifs.clearHistory()
                    }
                }
            }
        }

        // ONE FLOATING CARD PER NOTIFICATION
        Item {
            width: parent.width
            height: Services.Notifs.history.length > 0
                ? Math.min(historyPanel.listCap, histList.contentHeight)
                : 0

            visible: Services.Notifs.history.length > 0

            ListView {
                id: histList

                anchors.fill: parent

                clip: true

                model: Services.Notifs.history

                spacing: 8

                delegate: Rectangle {
                    id: histCard

                    required property var modelData
                    required property int index

                    readonly property bool selected:
                        historyPanel.panel.selectedIndex ===
                        historyPanel.panel.firstHistIdx() + index

                    // Same three icon shapes as ToastCard:
                    // ready-made image:// URL, file path, or
                    // bare theme name.
                    readonly property string rawIcon:
                        modelData.icon ?? ""
                    readonly property bool hasIcon: rawIcon !== ""
                    readonly property bool iconIsDirect:
                        rawIcon.startsWith("image://") ||
                        rawIcon.startsWith("/") ||
                        rawIcon.startsWith("file://")
                    readonly property string directSource:
                        rawIcon.startsWith("file://") ||
                        rawIcon.startsWith("image://")
                        ? rawIcon : "file://" + rawIcon
                    readonly property string themeIcon:
                        hasIcon && !iconIsDirect
                        ? Quickshell.iconPath(rawIcon, true) : ""

                    width: histList.width
                    height: content.height + 16

                    radius: 0

                    color: selected ? Palette.surfaceHover : Palette.bg

                    border.width: 1
                    border.color: modelData.critical
                        ? Palette.danger
                        : selected ? Palette.fg : Palette.border

                    MouseArea {
                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Services.Notifs.dismissHistoryAt(index)
                    }

                    Column {
                        id: content

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }

                        spacing: 6

                        Row {
                            width: parent.width
                            spacing: 8

                            Image {
                                anchors.verticalCenter: parent.verticalCenter

                                visible: histCard.hasIcon &&
                                    histCard.iconIsDirect

                                source: histCard.directSource

                                sourceSize.width: 32
                                sourceSize.height: 32

                                width: 32
                                height: 32

                                fillMode: Image.PreserveAspectFit
                            }

                            Image {
                                anchors.verticalCenter: parent.verticalCenter

                                visible: histCard.themeIcon !== ""

                                source: histCard.themeIcon

                                sourceSize.width: 32
                                sourceSize.height: 32

                                width: 32
                                height: 32

                                fillMode: Image.PreserveAspectFit
                            }

                            Column {
                                width: parent.width -
                                    (histCard.hasIcon ? 40 : 0)

                                spacing: 2

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter

                                        width: parent.width - 52

                                        text: modelData.summary ||
                                            modelData.app

                                        color: Palette.fg

                                        font.family: Palette.font
                                        font.pixelSize: Palette.px13
                                        font.bold: true

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter

                                        width: 44

                                        horizontalAlignment: Text.AlignRight

                                        text: Qt.formatDateTime(
                                            modelData.time, "HH:mm")

                                        color: Palette.dim

                                        font.family: Palette.font
                                        font.pixelSize: Palette.px10
                                    }
                                }

                                Text {
                                    width: parent.width

                                    visible: text !== ""

                                    text: modelData.body

                                    color: Palette.dim

                                    font.family: Palette.font
                                    font.pixelSize: Palette.px12

                                    textFormat: Text.RichText
                                    wrapMode: Text.WordWrap
                                }

                                // Live actions: the server object stays
                                // resident after hide, so these invoke
                                // for real; acting retires the row.
                                Flow {
                                    width: parent.width

                                    visible: modelData.live !== null &&
                                        modelData.live.actions.length > 0

                                    spacing: 6

                                    Repeater {
                                        model: modelData.live !== null
                                            ? modelData.live.actions : []

                                        delegate: Rectangle {
                                            required property var modelData

                                            width: actionLabel.width + 16
                                            height: 26

                                            radius: 0

                                            color: actionHover.containsMouse
                                                ? Palette.surfaceHover
                                                : Palette.surface

                                            border.width: 1
                                            border.color: Palette.border

                                            Text {
                                                id: actionLabel

                                                anchors.centerIn: parent

                                                text: modelData.text

                                                color: Palette.fg

                                                font.family: Palette.font
                                                font.pixelSize: Palette.px12
                                            }

                                            MouseArea {
                                                id: actionHover

                                                anchors.fill: parent

                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor

                                                onClicked: {
                                                    modelData.invoke()
                                                    Services.Notifs.dismissHistoryAt(
                                                        histCard.index)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
