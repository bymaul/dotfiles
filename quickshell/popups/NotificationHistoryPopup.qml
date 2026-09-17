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
    function close(): void {
        panel.close();
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
    Timer {
        id: polishTimer
        interval: Palette.focusDelay
        repeat: false
        onTriggered: {
            if (root.visible)
                historyList.positionViewAtIndex(0, ListView.Beginning);
        }
    }
    PanelNavKeys {
        host: root
        panel: root.panel
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
                    readonly property bool selected: root.panel.selectedKind() === "clear"
                    color: selected ? Palette.accent : clearArea.containsMouse ? Palette.fg : Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
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
                    border.width: modelData.critical ? 1 : 0
                    border.color: Palette.danger
                    MouseArea {
                        id: cardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.panel.selectIndex(root.panel.firstHistIdx() + historyCard.index);
                        }
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
                                            required property int index
                                            readonly property bool focused: historyCard.selected && root.panel.actionIndex === index
                                            width: actionLabel.width + 16
                                            height: 24
                                            color: focused ? Palette.accent : actionArea.containsMouse ? Palette.hoverBg : Palette.surface
                                            Text {
                                                id: actionLabel
                                                anchors.centerIn: parent
                                                text: modelData.text
                                                color: parent.focused ? Palette.onAccent : Palette.fg
                                                font.family: Palette.font
                                                font.pixelSize: Palette.px12
                                            }
                                            MouseArea {
                                                id: actionArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onContainsMouseChanged: {
                                                    if (containsMouse)
                                                        root.panel.selectAction(historyCard.index, index);
                                                }
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
