import QtQuick
import Quickshell
import "../components"
import "../services" as Services
import "../Palette.js" as Palette
BasePopup {
    id: root
    required property var panel
    useGrab: false
    extraTop: panel.height + Palette.popupSpacing
    implicitWidth: Palette.popupWidth
    readonly property int listCap: Math.max(96, Math.round(Screen.height / 2) - 32 - 8)
    implicitHeight: Palette.rowHeight + (Services.Notifs.history.length > 0 ? Palette.popupSpacing + Math.min(root.listCap, historyList.contentHeight) : 0)
    visible: panel.visible && Services.Notifs.history.length > 0
    // History visibility is derived from the panel. It must never set
    // visible directly (that breaks the binding and history stops showing).
    function close(): void {
        panel.close();
    }
    function revealAt(i: int): void {
        historyList.positionViewAtIndex(i, ListView.Contain);
    }
    onVisibleChanged: {
        // Re-sync the window height after the first layout pass: delegate
        // heights (wrapped text, action buttons) resolve after contentHeight
        // is first measured, which would otherwise leave the popup short.
        if (visible)
            polishTimer.restart();
    }
    Timer {
        id: polishTimer
        interval: Palette.focusDelay
        repeat: false
        onTriggered: {
            if (root.visible)
                historyList.positionViewAtIndex(0, ListView.Beginning);
        }
    }
    // Shortcuts are window-scoped, and focus can land in either the panel
    // or this window, so both need the same keymap forwarding to the panel.
    // Escape closes the panel (never this window directly).
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.panel.close()
    }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.panel.stepVertical(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.panel.stepVertical(-1) }
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.panel.adjustSelected(-1) }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.panel.adjustSelected(1) }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.panel.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.panel.activateSelected() }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.panel.activateSelected() }
    Shortcut { sequence: "m"; enabled: root.visible; onActivated: root.panel.toggleVolumeMute() }
    Shortcut { sequence: "c"; enabled: root.visible && Services.Notifs.history.length > 0; onActivated: Services.Notifs.clearHistory() }
    Shortcut { sequence: "o"; enabled: root.visible && Services.Notifs.history.length > 0; onActivated: root.panel.invokeSelectedAction() }
    Column {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: Palette.popupSpacing
        Rectangle {
            width: parent.width
            height: Palette.rowHeight
            color: Palette.bg
            Row {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 60
                    text: "Notifications (" + Services.Notifs.history.length + ")"
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
                    color: clearArea.containsMouse ? Palette.fg : Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                    MouseArea {
                        id: clearArea
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
            height: Services.Notifs.history.length > 0 ? Math.min(root.listCap, historyList.contentHeight) : 0
            visible: Services.Notifs.history.length > 0
            ListView {
                id: historyList
                anchors.fill: parent
                clip: true
                // Instantiate all delegates up front so contentHeight is
                // truthful on the first frame (the window height derives
                // from it). Histories are capped at 30 small cards.
                cacheBuffer: 10000
                model: Services.Notifs.history
                spacing: Palette.popupSpacing
                delegate: Rectangle {
                    id: historyCard
                    required property var modelData
                    required property int index
                    readonly property bool selected: root.panel.selectedIndex === root.panel.firstHistIdx() + index
                    readonly property string rawIcon: modelData.icon ?? ""
                    width: historyList.width
                    height: content.height + 16
                    color: selected ? Palette.activeBg : cardArea.containsMouse ? Palette.hoverBg : Palette.bg
                    border.width: 1
                    border.color: modelData.critical ? Palette.danger : selected ? Palette.accent : Palette.dim
                    MouseArea {
                        id: cardArea
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
                                id: historyIcon
                                rawIcon: historyCard.rawIcon
                            }
                            Column {
                                width: parent.width - (historyIcon.hasIcon ? 32 : 0)
                                spacing: 2
                                Row {
                                    width: parent.width
                                    spacing: 8
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 52
                                        text: modelData.summary || modelData.app || ""
                                        color: Palette.fg
                                        font.family: Palette.font
                                        font.pixelSize: Palette.px12
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 44
                                        horizontalAlignment: Text.AlignRight
                                        text: modelData.time ? Qt.formatDateTime(modelData.time, "HH:mm") : ""
                                        color: Palette.dim
                                        font.family: Palette.font
                                        font.pixelSize: Palette.px10
                                    }
                                }
                                Text {
                                    width: parent.width
                                    visible: (modelData.body ?? "") !== ""
                                    text: modelData.body ?? ""
                                    color: Palette.dim
                                    font.family: Palette.font
                                    font.pixelSize: Palette.px12
                                    textFormat: Text.RichText
                                    wrapMode: Text.WordWrap
                                }
                                Flow {
                                    width: parent.width
                                    visible: (modelData.live?.actions ?? []).length > 0
                                    spacing: 6
                                    Repeater {
                                        model: modelData.live?.actions ?? []
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: actionLabel.width + 16
                                            height: 24
                                            color: actionArea.containsMouse ? Palette.hoverBg : Palette.surface
                                            Text {
                                                id: actionLabel
                                                anchors.centerIn: parent
                                                text: modelData.text
                                                color: Palette.fg
                                                font.family: Palette.font
                                                font.pixelSize: Palette.px12
                                            }
                                            MouseArea {
                                                id: actionArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Services.Notifs.activateAction(historyCard.modelData.live, modelData);
                                                    Services.Notifs.dismissHistoryAt(historyCard.index);
                                                    bar.closePopups();
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
