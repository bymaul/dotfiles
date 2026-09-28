import QtQuick
import "../services" as Services
Column {
    id: root
    property string statusText: ""
    property color statusColor: Services.Theme.dim
    property string enableLabel: ""
    property string scanLabel: ""
    signal enableClicked()
    signal scanClicked()
    width: parent.width
    spacing: Services.Theme.popupSpacing
    Rectangle {
        width: parent.width
        height: Services.Theme.rowHeight
        color: Services.Theme.transparent
        Text {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 10
            }
            width: parent.width - 20
            text: root.statusText
            color: root.statusColor
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px12
            elide: Text.ElideRight
        }
    }
    Row {
        width: parent.width
        height: Services.Theme.rowHeight
        spacing: Services.Theme.popupSpacing
        PopupButton {
            label: root.enableLabel
            onClicked: root.enableClicked()
        }
        PopupButton {
            label: root.scanLabel
            onClicked: root.scanClicked()
        }
    }
}
