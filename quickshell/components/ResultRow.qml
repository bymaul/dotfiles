import QtQuick
import "../services" as Services

Rectangle {
    id: root
    required property bool selected
    property bool highlighted: false
    property int rowHeight: Services.Theme.rowHeight
    property color baseColor: Services.Theme.transparent
    signal hovered()
    signal clicked()
    readonly property bool isHovered: rowArea.containsMouse
    width: ListView.view.width
    height: root.rowHeight
    color: root.selected ? Services.Theme.accent : rowArea.containsMouse ? Services.Theme.hoverBg : (root.highlighted ? Services.Theme.activeBg : root.baseColor)
    MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (containsMouse)
                root.hovered();
        }
        onClicked: root.clicked()
    }
}
