import QtQuick
import Quickshell.Services.Notifications
import "../services" as Services
Rectangle {
    id: card
    required property var notification
    property int seq: Services.Notifs.toastSeq
    property string contentSig: ""
    property string cheapSig: ""
    function syncHover(): void {
        if (card.hovered)
            expiryTimer.stop();
        else
            card.maybeRestartExpiry();
    }
    function maybeRestartExpiry(): void {
        if (!card.hovered && !card.neverExpire)
            expiryTimer.restart();
    }
    function refreshSig(): void {
        const n = card.notification;
        const cheap = n ? [n.summary ?? "", n.body ?? "", n.appIcon ?? "", n.image ?? "", n.expireTimeout ?? "", card.valueHint].join("\u0001") : "";
        if (cheap !== card.cheapSig) {
            card.cheapSig = cheap;
            if (card.contentSig !== "")
                card.maybeRestartExpiry();
            card.contentSig = cheap + (n && n.hints ? JSON.stringify(n.hints) : "");
            return;
        }
        const full = cheap + (n && n.hints ? JSON.stringify(n.hints) : "");
        if (full !== card.contentSig) {
            card.maybeRestartExpiry();
            card.contentSig = full;
        }
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
    readonly property var visibleActions: Services.Notifs.secondaryActionsOf(card.actionList)
    readonly property bool neverExpire: {
        card.seq;
        return Services.Notifs.effectiveTimeout(card.notification) < 0;
    }
    readonly property int autoDismissMs: {
        card.seq;
        return Math.max(0, Services.Notifs.effectiveTimeout(card.notification));
    }
    readonly property bool hovered: cardArea.containsMouse || bodyHover.containsMouse || dismissArea.containsMouse
    MouseArea {
        id: cardArea
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: card.syncHover()
        onClicked: mouse => {
            mouse.accepted = true;
            let ok = false;
            try {
                ok = Services.Notifs.activateDefault(card.notification);
            } catch (_) {
                ok = false;
            }
            Services.Notifs.finishToastAfterAction(card.notification, ok);
        }
    }
    Timer {
        id: expiryTimer
        interval: card.autoDismissMs
        running: !card.neverExpire
        repeat: false
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
                tint: card.notification.urgency === NotificationUrgency.Critical ? Services.Theme.danger : "transparent"
            }
            Column {
                width: parent.width - (cardIcon.showIcon ? cardIcon.width + 8 : 0)
                spacing: 2
                Row {
                    width: parent.width
                    height: 20
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - timeText.width - dismissSlot.width - parent.spacing * 2
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
                        id: timeText
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        horizontalAlignment: Text.AlignRight
                        text: {
                            card.seq;
                            Services.Notifs.timeTick;
                            return Services.Notifs.timeAgo(card.notification.addedAt ?? 0);
                        }
                        color: Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px10
                    }
                    Item {
                        id: dismissSlot
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 20
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰅖"
                            color: dismissArea.containsMouse ? Services.Theme.fg : Services.Theme.dim
                            font.family: Services.Theme.font
                            font.pixelSize: Services.Theme.px10
                        }
                        MouseArea {
                            id: dismissArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                mouse.accepted = true;
                                Services.Notifs.hideToast(card.notification);
                            }
                        }
                    }
                }
                Text {
                    id: bodyText
                    width: parent.width
                    visible: text !== ""
                    text: {
                        card.seq;
                        return Services.Notifs.richBody(card.notification.body);
                    }
                    color: Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    textFormat: Text.RichText
                    wrapMode: Text.WordWrap
                }
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
            actions: card.visibleActions
            onPicked: action => {
                let ok = false;
                try {
                    ok = Services.Notifs.activateAction(card.notification, action);
                } catch (_) {
                    ok = false;
                }
                Services.Notifs.finishToastAfterAction(card.notification, ok);
            }
        }
    }
    MouseArea {
        id: bodyHover
        anchors.fill: bodyText
        visible: bodyText.visible
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: card.syncHover()
    }
}
