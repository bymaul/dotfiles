import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../services" as Services
import "../Palette.js" as Palette
Rectangle {
    id: card
    required property var notification
    property bool parked: false
    property int seq: Services.Notifs.toastSeq
    onSeqChanged: {
        if (card.notification?.qsInternal === true)
            expiryTimer.restart();
    }
    width: Palette.popupWidth
    height: content.height + 16
    color: Palette.bg
    border.width: 1
    border.color: {
        card.seq;
        return card.notification.urgency === NotificationUrgency.Critical || (card.notification.appName === "volume" && card.notification.summary === "Muted") ? Palette.danger : Palette.dim;
    }
    readonly property var valueHint: {
        card.seq;
        return notification.hints ? notification.hints["value"] : undefined;
    }
    readonly property bool hasProgress: valueHint !== undefined && !isNaN(Number(valueHint))
    readonly property string rawIcon: {
        card.seq;
        const hit = [notification.image, notification.appIcon].find(s => typeof s === "string" && s !== "");
        return hit ?? "";
    }
    readonly property var actionList: card.notification?.actions ?? []
    MouseArea {
        anchors.fill: parent
        onClicked: {
            const path = Services.Notifs.filepathOf(card.notification);
            if (path !== "")
                Quickshell.execDetached(["xdg-open", path]);
            Services.Notifs.hideToast(card.notification);
            Services.Notifs.forgetLive(card.notification);
        }
    }
    Timer {
        id: expiryTimer
        interval: card.notification.expireTimeout > 0 ? card.notification.expireTimeout : Palette.toastTimeout
        running: true
        onTriggered: Services.Notifs.hideToast(card.notification)
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
                id: cardIcon
                rawIcon: card.rawIcon
            }
            Column {
                width: parent.width - (cardIcon.hasIcon ? cardIcon.width + 8 : 0)
                spacing: 2
                Text {
                    width: parent.width
                    text: {
                        card.seq;
                        return card.notification.summary;
                    }
                    color: Palette.fg
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: {
                        card.seq;
                        return card.notification.body;
                    }
                    color: Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                    textFormat: Text.RichText
                    wrapMode: Text.WordWrap
                }
            }
        }
        Rectangle {
            width: parent.width
            height: 3
            visible: card.hasProgress
            color: Palette.onAccent
            Rectangle {
                width: parent.width * Palette.clamp01(Number(card.valueHint) / 100)
                height: parent.height
                color: Palette.accent
                Behavior on width {
                    NumberAnimation {
                        duration: 120
                    }
                }
            }
        }
        Flow {
            width: parent.width
            visible: card.actionList.length > 0
            spacing: 6
            Repeater {
                model: card.actionList
                delegate: Rectangle {
                    required property var modelData
                    width: actionLabel.width + 16
                    height: 24
                    color: hover.containsMouse ? Palette.hoverBg : Palette.surface
                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData.text
                        color: Palette.fg
                        font.family: Palette.font
                        font.pixelSize: Palette.px12
                    }
                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Services.Notifs.activateAction(card.notification, modelData))
                                Services.Notifs.hideToast(card.notification);
                        }
                    }
                }
            }
        }
    }
}
