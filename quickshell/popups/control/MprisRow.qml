import QtQuick
import "../../services" as Services

Rectangle {
    id: root
    required property var popup
    visible: popup.mprisPlayer !== null
    width: parent.width
    height: visible ? Services.Theme.rowHeight : 0
    color: popup.selectedKind() === "mpris" ? Services.Theme.activeBg : Services.Theme.surface
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: {
            if (containsMouse)
                popup.selectMpris(popup.mprisCol);
        }
    }
    Item {
        id: artBox
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 10
        }
        width: 28
        height: 28
        Text {
            anchors.centerIn: parent
            visible: artImg.status !== Image.Ready
            text: "󰝚"
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px14
        }
        Image {
            id: artImg
            anchors.fill: parent
            visible: status === Image.Ready
            source: popup.mprisPlayer?.trackArtUrl ?? ""
            asynchronous: true
            cache: false
            smooth: true
            sourceSize.width: 56
            sourceSize.height: 56
            fillMode: Image.PreserveAspectCrop
        }
    }
    Column {
        anchors {
            left: artBox.right
            right: transportBtns.left
            verticalCenter: parent.verticalCenter
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 0
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: popup.mprisPlayer?.trackTitle || popup.mprisPlayer?.identity || "Unknown"
            color: Services.Theme.fg
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px12
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: {
                const parts = [popup.mprisPlayer?.trackArtist, popup.mprisPlayer?.trackAlbum].filter(s => s);
                return parts.length > 0 ? parts.join(" · ") : (popup.mprisPlayer?.identity ?? "");
            }
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px10
        }
    }
    Row {
        id: transportBtns
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 10
        }
        spacing: 6
        MprisButton {
            popup: root.popup
            col: 0
            text: "󰒮"
            canUse: popup.mprisPlayer?.canGoPrevious ?? true
        }
        MprisButton {
            popup: root.popup
            col: 1
            text: (popup.mprisPlayer?.isPlaying ?? false) ? "󰏤" : "󰐊"
            canUse: popup.mprisPlayer?.canTogglePlaying ?? true
        }
        MprisButton {
            popup: root.popup
            col: 2
            text: "󰒭"
            canUse: popup.mprisPlayer?.canGoNext ?? true
        }
        MprisButton {
            popup: root.popup
            col: 3
            visible: popup.playerCount > 1
            width: visible ? 34 : 0
            btnWidth: 34
            px: Services.Theme.px10
            text: (Services.Media.activePlayerIndex + 1) + "/" + popup.playerCount
            color: (popup.selectedKind() === "mpris" && popup.mprisCol === 3) ? Services.Theme.accentFg : Services.Theme.dim
        }
    }
}
