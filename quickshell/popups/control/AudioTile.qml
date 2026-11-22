import QtQuick
import "../../services" as Services

Rectangle {
    id: root
    property bool selected: false
    signal clicked()

    width: 40
    height: Services.Theme.rowHeight
    readonly property bool isHovered: tileArea.containsMouse
    color: root.selected ? Services.Theme.activeBg : root.isHovered ? Services.Theme.hoverBg : Services.Theme.surface
    border.width: root.selected ? 1 : 0
    border.color: root.isHovered ? Services.Theme.fg : Services.Theme.accent
    Text {
        anchors.centerIn: parent
        text: "󰓃"
        color: root.selected || root.isHovered ? Services.Theme.fg : Services.Theme.dim
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px14
    }
    MouseArea {
        id: tileArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
