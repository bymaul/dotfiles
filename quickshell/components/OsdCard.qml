import QtQuick
import "../services" as Services

Rectangle {
    id: card
    required property var notification
    property int seq: Services.Notifs.toastSeq
    property string contentSig: ""
    function refreshSig(): void {
        const n = card.notification;
        const sig = n ? [n.summary ?? "", n.appIcon ?? "", n.expireTimeout ?? "", n.hints ? JSON.stringify(n.hints) : ""].join("\u0001") : "";
        if (card.contentSig !== "" && sig !== card.contentSig)
            expiryTimer.restart();
        card.contentSig = sig;
    }
    onSeqChanged: card.refreshSig()
    Component.onCompleted: card.refreshSig()
    width: Services.Theme.osdWidth
    height: 28
    color: Services.Theme.bg
    border.width: 1
    border.color: Services.Theme.dim
    readonly property var valueHint: {
        card.seq;
        return notification.hints ? notification.hints["value"] : undefined;
    }
    readonly property bool hasProgress: valueHint !== undefined && !isNaN(Number(valueHint))
    readonly property string syncKey: {
        card.seq;
        var n = card.notification;
        return n && n.qsSyncKey ? String(n.qsSyncKey) : "";
    }
    readonly property bool showBar: card.hasProgress && card.syncKey !== "charger"
    readonly property string glyph: {
        card.seq;
        var n = card.notification;
        var key = card.syncKey;
        var icon = n && n.appIcon ? String(n.appIcon) : "";
        var summary = n && n.summary ? String(n.summary) : "";
        if (key === "brightness")
            return "󰃟";
        if (key === "mic")
            return (summary.indexOf("Muted") !== -1 || summary.indexOf("No ") !== -1 || icon.indexOf("muted") !== -1) ? "󰍭" : "󰍬";
        if (key === "media")
            return "󰝚";
        if (key === "caffeine")
            return "󰅶";
        if (key === "dnd")
            return "";
        if (key === "charger") {
            if (summary === "Charger connected")
                return "󰂄";
            var cv = Number(card.valueHint);
            if (!isNaN(cv)) {
                if (cv >= 90)
                    return "󰁹";
                if (cv >= 70)
                    return "󰂂";
                if (cv >= 50)
                    return "󰁾";
                if (cv >= 30)
                    return "󰁼";
                if (cv >= 10)
                    return "󰁺";
                return "󰂎";
            }
            return "󰁹";
        }
        if (summary === "Muted" || summary.indexOf("No ") !== -1 || summary.indexOf("unavailable") !== -1)
            return "󰝟";
        const v = Number(card.valueHint);
        if (!isNaN(v)) {
            if (v <= 30)
                return "󰖀";
            if (v < 100)
                return "󰕾";
            return "󰝝";
        }
        return "󰕾";
    }
    MouseArea {
        anchors.fill: parent
        onClicked: Services.Notifs.dismissToast(card.notification)
    }
    Timer {
        id: expiryTimer
        interval: card.notification.expireTimeout > 0 ? card.notification.expireTimeout : Services.Theme.toastTimeout
        running: !(card.notification.resident === true)
        onTriggered: Services.Notifs.dismissToast(card.notification)
    }
    Row {
        id: row
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 0
        Text {
            id: glyphItem
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            text: card.glyph
            color: Services.Theme.fg
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px13
        }
        Text {
            id: labelItem
            anchors.verticalCenter: parent.verticalCenter
            width: card.showBar ? 40 : row.width - glyphItem.width - row.spacing
            text: {
                card.seq;
                var n = card.notification;
                var key = n && n.qsSyncKey ? String(n.qsSyncKey) : "";
                if (key === "charger" && card.hasProgress)
                    return Math.round(Number(card.valueHint)) + "%";
                return card.notification.summary;
            }
            color: Services.Theme.fg
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px11
            elide: Text.ElideRight
        }
        ProgressBar {
            anchors.verticalCenter: parent.verticalCenter
            width: card.showBar ? row.width - glyphItem.width - labelItem.width - row.spacing * 2 : 0
            height: 3
            visible: card.showBar
            fraction: Number(card.valueHint) / 100
        }
    }
}
