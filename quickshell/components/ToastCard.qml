import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../services" as Services
import "../Palette.js" as Palette

Rectangle {
    id: card

    required property var notification

    width: Palette.popupWidth
    height: content.height + 16

    radius: 0

    property bool parked: false
    color: Palette.bg

    border.width: 1
    border.color: card.notification.urgency === NotificationUrgency.Critical || (card.notification.appName === "volume" && card.notification.summary === "Muted") ? Palette.danger : Palette.dim

    readonly property var valueHint: notification.hints ? notification.hints["value"] : undefined
    readonly property bool hasProgress: valueHint !== undefined && !isNaN(Number(valueHint))
    readonly property string rawIcon: {
        const cands = [notification.image, notification.appIcon];
        const hit = cands.find(s => typeof s === "string" && s !== "");

        return hit ?? "";
    }

    MouseArea {
        anchors.fill: parent

        onClicked: {
            if (Services.Notifs.filepathOf(card.notification) !== "")
                Quickshell.execDetached(["xdg-open", Services.Notifs.filepathOf(card.notification)]);
            else
                Services.Notifs.hideToast(card.notification);

            Services.Notifs.forgetLive(card.notification);
        }
    }

    // expireTimeout is MILLISECONDS despite the docs. Hide only:
    // the object stays resident for history buttons.
    Timer {
        interval: card.notification.expireTimeout > 0 ? card.notification.expireTimeout : 5000
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
                width: parent.width - (cardIcon.hasIcon ? 32 : 0)

                spacing: 2

                Text {
                    width: parent.width

                    text: card.notification.summary

                    color: Palette.fg

                    font.family: Palette.font
                    font.pixelSize: Palette.px12

                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width

                    visible: text !== ""

                    text: card.notification.body

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

            radius: 0

            color: Palette.onAccent

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, Number(card.valueHint) / 100))
                height: parent.height

                radius: 0

                color: Palette.accent
            }
        }

        Flow {
            width: parent.width

            visible: card.notification.actions.length > 0

            spacing: 6

            Repeater {
                model: card.notification.actions

                delegate: Rectangle {
                    required property var modelData

                    width: actionLabel.width + 16
                    height: 24

                    radius: 0

                    color: actionHover.containsMouse ? Palette.hoverBg : Palette.surface

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
                            if (Services.Notifs.activateAction(card.notification, modelData))
                                Services.Notifs.hideToast(card.notification);
                        }
                    }
                }
            }
        }
    }
}
