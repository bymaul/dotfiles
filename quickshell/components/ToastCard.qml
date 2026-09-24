import QtQuick
import Quickshell.Services.Notifications
import "../services" as Services
Rectangle {
    id: card
    required property var notification
    property int seq: Services.Notifs.toastSeq
    property string contentSig: ""
    function refreshSig(): void {
        const n = card.notification;
        const sig = n ? [n.summary ?? "", n.body ?? "", n.appIcon ?? "", n.image ?? "", n.expireTimeout ?? "", n.hints ? JSON.stringify(n.hints) : ""].join("\u0001") : "";
        if (card.contentSig !== "" && sig !== card.contentSig && !cardArea.containsMouse)
            expiryTimer.restart();
        card.contentSig = sig;
    }
    onSeqChanged: card.refreshSig()
    Component.onCompleted: card.refreshSig()
    width: Services.Theme.popupWidth
    height: content.height + 16
    color: Services.Theme.bg
    border.width: 1
    border.color: {
        card.seq;
        return card.notification.urgency === NotificationUrgency.Critical || (card.notification.appName === "volume" && card.notification.summary === "Muted") ? Services.Theme.danger : Services.Theme.dim;
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
    readonly property var actionList: card.notification && card.notification.actions ? card.notification.actions : []
    readonly property bool sticky: card.notification.resident === true || (card.notification.expireTimeout ?? -1) === 0
    MouseArea {
        id: cardArea
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: {
            if (containsMouse)
                expiryTimer.stop();
            else
                expiryTimer.restart();
        }
        onClicked: {
            if (Services.Notifs.activateDefault(card.notification))
                Services.Notifs.consumeToast(card.notification);
            else
                Services.Notifs.hideToast(card.notification);
        }
    }
    Timer {
        id: expiryTimer
        interval: card.notification.expireTimeout > 0 ? card.notification.expireTimeout : (card.sticky ? Services.Theme.toastStickyTimeout : Services.Theme.toastTimeout)
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
                width: parent.width - (cardIcon.showIcon ? cardIcon.width + 8 : 0) - (closeBox.width + 8)
                spacing: 2
                Text {
                    width: parent.width
                    text: {
                        card.seq;
                        return card.notification.summary;
                    }
                    color: Services.Theme.fg
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: {
                        card.seq;
                        return card.notification.body;
                    }
                    color: Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    textFormat: Text.RichText
                    wrapMode: Text.WordWrap
                }
            }
            CardCloseButton {
                id: closeBox
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Services.Notifs.hideToast(card.notification)
            }
        }
        ProgressBar {
            width: parent.width
            height: 3
            visible: card.hasProgress
            fraction: Number(card.valueHint) / 100
        }
        ActionPills {
            width: parent.width
            actions: card.actionList
            onPicked: action => {
                if (Services.Notifs.activateAction(card.notification, action))
                    Services.Notifs.consumeToast(card.notification);
                else
                    Services.Notifs.hideToast(card.notification);
            }
        }
    }
}
