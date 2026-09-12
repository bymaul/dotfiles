import QtQuick
import Quickshell
import "../components"
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
BasePopup {
    id: historyPanel

    required property var panel

    // Covered by the bar-level grab alongside the control panel.
    useGrab: false

    extraTop: panel.height + 8

    implicitWidth: Palette.popupWidth

    // Header bar 34 + spacing + scrollable cards, capped at half
    // the screen. Hidden entirely when there is no history.
    readonly property int listCap: Math.max(96,
        Math.round(Screen.height / 2) - 32 - 8)

    implicitHeight: 32 + (Services.Notifs.history.length > 0
        ? 8 + Math.min(historyPanel.listCap, histList.contentHeight)
        : 0)

    visible: panel.visible && Services.Notifs.history.length > 0

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
        sequence: "j"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.stepVertical(1)
    }
    Shortcut {
        sequence: "k"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.stepVertical(-1)
    }
    Shortcut {
        sequence: "h"
        enabled: historyPanel.visible
        onActivated: historyPanel.panel.adjustSelected(-1)
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
    Shortcut {
        sequence: "c"
        enabled: historyPanel.visible &&
            Services.Notifs.history.length > 0
        onActivated: Services.Notifs.clearHistory()
    }
    Shortcut {
        sequence: "o"
        enabled: historyPanel.visible &&
            Services.Notifs.history.length > 0
        onActivated: historyPanel.panel.invokeSelectedAction()
    }

    Column {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        spacing: Palette.popupSpacing

        Rectangle {
            width: parent.width
            height: 32

            radius: 0

            color: Palette.bg

            border.width: 0

            Row {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    width: parent.width - 60

                    text: "Notifications (" +
                        Services.Notifs.history.length + ")"

                    color: Palette.dim

                    font.family: Palette.font
                    font.pixelSize: Palette.px12

                    elide: Text.ElideRight
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

                    width: histList.width
                    height: content.height + 16

                    radius: 0

                    color: selected ? Palette.accent
                        : histHover.containsMouse ? Palette.hoverBg : Palette.bg

                    border.width: 1
                    border.color: modelData.critical
                        ? Palette.danger
                        : selected ? Palette.accent : Palette.dim

                    MouseArea {
                        id: histHover

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

                            NotificationIcon {
                                id: histIcon

                                rawIcon: histCard.rawIcon
                            }

                            Column {
                                width: parent.width -
                                    (histIcon.hasIcon ? 32 : 0)

                                spacing: 2

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter

                                        width: parent.width - 52

                                        text: modelData.summary ||
                                            modelData.app

                                        color: selected ? Palette.onAccent
                                            : Palette.fg

                                        font.family: Palette.font
                                        font.pixelSize: Palette.px12

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter

                                        width: 44

                                        horizontalAlignment: Text.AlignRight

                                        text: Qt.formatDateTime(
                                            modelData.time, "HH:mm")

                                        color: selected ? Palette.onAccent
                                            : Palette.dim

                                        font.family: Palette.font
                                        font.pixelSize: Palette.px10
                                    }
                                }

                                Text {
                                    width: parent.width

                                    visible: text !== ""

                                    text: modelData.body

                                    color: selected ? Palette.onAccent
                                        : Palette.dim

                                    font.family: Palette.font
                                    font.pixelSize: Palette.px12

                                    textFormat: Text.RichText
                                    wrapMode: Text.WordWrap
                                }

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
                                            height: 24

                                            radius: 0

                                            color: actionHover.containsMouse
                                                ? Palette.hoverBg
                                                : Palette.surface

                                            border.width: 0

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
                                                Services.Notifs.activateAction(
                                                    histCard.modelData.live,
                                                    modelData)
                                                Services.Notifs.dismissHistoryAt(
                                                    histCard.index)
                                                bar.closePopups()
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
