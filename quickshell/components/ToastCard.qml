import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../services" as Services
import "../Palette.js" as Palette

Rectangle {
    id: card

    required property var notification

    // Default width; ToastStack overrides per context (parked =
    // popupWidth, floating = toastWidth).
    width: Palette.popupWidth
    height: content.height + 16

    radius: 0

    // Elevated surface, not base bg: a parked toast sits directly on
    // top of history cards (same anchor/width), and identical
    // backgrounds melt it into the list. Surface keeps it readable
    // as the topmost layer.
    color: Palette.surface

    border.width: 1
    border.color: card.notification.urgency === NotificationUrgency.Critical ||
        (card.notification.appName === "volume" &&
            card.notification.summary === "Muted")
        ? Palette.danger : Palette.border

    readonly property var valueHint: notification.hints
        ? notification.hints["value"] : undefined
    readonly property bool hasProgress: valueHint !== undefined &&
        !isNaN(Number(valueHint))
    // -i arrives as a theme name (appIcon), a file path (appIcon or
    // image), or a ready-made image:// URL (image, server-resolved).
    // Only bare names go through theme lookup; URLs load directly.
    readonly property string rawIcon: {
        const cands = [notification.image, notification.appIcon]
        const hit = cands.find(s => typeof s === "string" && s !== "")

        return hit ?? ""
    }
    readonly property bool hasIcon: card.rawIcon !== ""
    readonly property bool iconIsDirect: card.rawIcon.startsWith("image://") ||
        card.rawIcon.startsWith("/") || card.rawIcon.startsWith("file://")
    readonly property string directSource: card.rawIcon.startsWith("file://") ||
        card.rawIcon.startsWith("image://")
        ? card.rawIcon : "file://" + card.rawIcon
    // Theme names resolve through the platform theme; the check
    // variant yields "" instead of a missing-texture square.
    readonly property string themeIcon: card.hasIcon && !card.iconIsDirect
        ? Quickshell.iconPath(card.rawIcon, true) : ""

    // Click (behind the action buttons): default action when the
    // notification has actions, dismiss otherwise. Mirrors mako's
    // [actionable] split and replaces its rofi middle-click menu
    // with the inline buttons below.
    MouseArea {
        anchors.fill: parent

        onClicked: {
            const def = card.notification.actions.find(
                a => a.identifier === "default"
            ) ?? card.notification.actions[0] ?? null

            if (def)
                def.invoke()
            else
                card.notification.dismiss()

            Services.Notifs.forgetLive(card.notification)
        }
    }

    // expireTimeout is MILLISECONDS despite what the docs claim
    // (-t 1500 arrives as 1500, unset as -1). Timeout hides, never
    // expires: the object stays resident for history buttons.
    Timer {
        interval: card.notification.expireTimeout > 0
            ? card.notification.expireTimeout : 5000
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

                Image {
                anchors.verticalCenter: parent.verticalCenter

                visible: card.hasIcon && card.iconIsDirect

                source: card.directSource

                sourceSize.width: 32
                sourceSize.height: 32

                width: 32
                height: 32

                fillMode: Image.PreserveAspectFit
            }

            Image {
                anchors.verticalCenter: parent.verticalCenter

                visible: card.themeIcon !== ""

                source: card.themeIcon

                sourceSize.width: 32
                sourceSize.height: 32

                width: 32
                height: 32

                fillMode: Image.PreserveAspectFit
            }

            Column {
                width: parent.width - (card.hasIcon ? 40 : 0)

                spacing: 2

                Text {
                    width: parent.width

                    text: card.notification.summary

                    color: Palette.fg

                    font.family: Palette.font
                    font.pixelSize: Palette.px13
                    font.bold: true

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

        // OSD-style progress (osd-volume/osd-brightness int:value).
        Rectangle {
            width: parent.width
            height: 6

            visible: card.hasProgress

            radius: 0

            color: Palette.onAccent

            Rectangle {
                width: parent.width *
                    Math.max(0, Math.min(1, Number(card.valueHint) / 100))
                height: parent.height

                radius: 0

                color: Palette.accent
            }
        }

        // Inline action buttons (screenshot Open/Copy path, ...).
        Flow {
            width: parent.width

            visible: card.notification.actions.length > 0

            spacing: 6

            Repeater {
                model: card.notification.actions

                delegate: Rectangle {
                    required property var modelData

                    width: actionLabel.width + 16
                    height: 26

                    radius: 0

                    color: actionHover.containsMouse
                        ? Palette.surfaceHover : Palette.surface

                    border.width: 1
                    border.color: Palette.border

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

                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
