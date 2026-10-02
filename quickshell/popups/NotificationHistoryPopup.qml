import QtQuick
import Quickshell
import "../components"
import "../services" as Services
BasePopup {
    id: root
    required property var panel
    useGrab: false
    extraTop: panel.height + Services.Theme.popupSpacing
    implicitWidth: Services.Theme.popupWidth
    readonly property int listCap: Math.max(96, Math.round(Screen.height / 2) - 32 - 8)
    implicitHeight: Services.Theme.rowHeight + (Services.Notifs.history.length > 0 ? Services.Theme.popupSpacing + Math.min(root.listCap, historyList.contentHeight) : 0)
    visible: panel.visible && Services.Notifs.history.length > 0
    function close(): void {
        panel.close();
    }
    function rebindVisibility(): void {
        root.visible = Qt.binding(function() {
            return root.panel.visible && Services.Notifs.history.length > 0;
        });
    }
    function cancelOrClose(): void {
        root.panel.close();
    }
    function revealAt(i: int): void {
        historyList.positionViewAtIndex(i, ListView.Contain);
    }
    onVisibleChanged: {
        if (visible)
            polishTimer.restart();
    }
    PanelNavKeys {
        host: root
        panel: root.panel
    }
    Shortcut { sequence: "["; enabled: root.visible; onActivated: root.panel.stepSection(-1) }
    Shortcut { sequence: "]"; enabled: root.visible; onActivated: root.panel.stepSection(1) }
    Timer {
        id: polishTimer
        interval: Services.Theme.focusDelay
        repeat: false
        onTriggered: {
            if (root.visible)
                historyList.positionViewAtIndex(0, ListView.Beginning);
        }
    }
    Column {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: Services.Theme.popupSpacing
        Rectangle {
            width: parent.width
            height: Services.Theme.rowHeight
            color: Services.Theme.bg
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
                    color: Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    elide: Text.ElideRight
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 60
                    horizontalAlignment: Text.AlignRight
                    text: "Clear"
                    readonly property bool selected: root.panel.selectedKind() === "clear"
                    color: selected ? Services.Theme.accent : clearArea.containsMouse ? Services.Theme.fg : Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    font.underline: selected
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse && Services.Notifs.history.length > 0)
                                root.panel.selectIndex(root.panel.clearIdx());
                        }
                        onClicked: {
                            root.panel.actionIndex = -1;
                            Services.Notifs.clearHistory();
                            root.panel.clampSelection();
                        }
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
                cacheBuffer: 400
                model: Services.Notifs.history
                spacing: Services.Theme.popupSpacing
                delegate: Rectangle {
                    id: historyCard
                    required property var modelData
                    required property int index
                    readonly property bool selected: root.panel.selectedIndex === root.panel.firstHistIdx() + index
                    readonly property string rawIcon: modelData.icon ?? ""
                    width: historyList.width
                    height: content.height + 16
                    color: selected ? Services.Theme.activeBg : cardArea.containsMouse ? Services.Theme.hoverBg : Services.Theme.bg
                    border.width: modelData.critical ? 1 : 0
                    border.color: Services.Theme.danger
                    MouseArea {
                        id: cardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.panel.selectIndex(root.panel.firstHistIdx() + historyCard.index);
                        }
                        onClicked: mouse => {
                            mouse.accepted = true;
                            const idx = historyCard.index;
                            const live = historyCard.modelData.live;
                            if (live == null) {
                                root.panel.actionIndex = -1;
                                Services.Notifs.dismissHistoryAt(idx);
                                root.panel.clampSelection();
                                return;
                            }
                            try {
                                Services.Notifs.activateDefault(live);
                            } catch (_) {}
                            root.panel.actionIndex = -1;
                            Services.Notifs.dismissHistoryAt(idx);
                            root.panel.clampSelection();
                            bar.closePopups();
                        }
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
                                width: parent.width - (historyIcon.showIcon ? 32 : 0)
                                spacing: 2
                                Row {
                                    width: parent.width
                                    spacing: 8
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 80
                                        text: modelData.summary || modelData.app || ""
                                        color: Services.Theme.fg
                                        font.family: Services.Theme.font
                                        font.pixelSize: Services.Theme.px12
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 44
                                        horizontalAlignment: Text.AlignRight
                                        text: modelData.time ? Qt.formatDateTime(modelData.time, "HH:mm") : ""
                                        color: Services.Theme.dim
                                        font.family: Services.Theme.font
                                        font.pixelSize: Services.Theme.px10
                                    }
                                    CardCloseButton {
                                        anchors.verticalCenter: parent.verticalCenter
                                        onClicked: {
                                            root.panel.actionIndex = -1;
                                            Services.Notifs.dismissHistoryAt(historyCard.index);
                                            root.panel.clampSelection();
                                        }
                                    }
                                }
                                Text {
                                    width: parent.width
                                    visible: (modelData.body ?? "") !== ""
                                    text: modelData.body ?? ""
                                    color: Services.Theme.dim
                                    font.family: Services.Theme.font
                                    font.pixelSize: Services.Theme.px12
                                    textFormat: Text.RichText
                                    wrapMode: Text.WordWrap
                                }
                                ActionPills {
                                    width: parent.width
                                    actions: Services.Notifs.secondaryActionsOf(modelData.live?.actions ?? [])
                                    focusedIndex: historyCard.selected ? root.panel.actionIndex : -1
                                    onHovered: index => root.panel.selectAction(historyCard.index, index)
                                    onPicked: action => {
                                        const idx = historyCard.index;
                                        try {
                                            Services.Notifs.activateAction(modelData.live, action);
                                        } catch (_) {}
                                        root.panel.actionIndex = -1;
                                        Services.Notifs.dismissHistoryAt(idx);
                                        root.panel.clampSelection();
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
