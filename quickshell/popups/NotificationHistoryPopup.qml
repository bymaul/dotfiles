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
        interval: Services.Theme.focusDelay
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
                        onClicked: {
                            if (Services.Notifs.activateDefault(historyCard.modelData.live))
                                bar.closePopups();
                            Services.Notifs.dismissHistoryAt(historyCard.index);
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
                                    Item {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 20
                                        height: 20
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            color: histCloseArea.containsMouse ? Services.Theme.fg : Services.Theme.dim
                                            font.family: Services.Theme.font
                                            font.pixelSize: Services.Theme.px12
                                        }
                                        MouseArea {
                                            id: histCloseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Services.Notifs.dismissHistoryAt(historyCard.index)
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
                                            color: focused ? Services.Theme.accent : actionArea.containsMouse ? Services.Theme.hoverBg : Services.Theme.surface
                                            Text {
                                                id: actionLabel
                                                anchors.centerIn: parent
                                                text: modelData.text
                                                color: parent.focused ? Services.Theme.onAccent : Services.Theme.fg
                                                font.family: Services.Theme.font
                                                font.pixelSize: Services.Theme.px12
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
