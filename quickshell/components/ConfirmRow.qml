import QtQuick
import "../Palette.js" as Palette
Row {
    id: root
    required property int choice
    required property string noLabel
    required property string yesLabel
    signal picked(int index)
    signal hovered(int index)
    width: parent.width
    spacing: Palette.popupSpacing
    PopupButton {
        label: root.noLabel
        columns: 2
        selected: root.choice === 0
        onClicked: root.picked(0)
        onHovered: root.hovered(0)
    }
    PopupButton {
        label: root.yesLabel
        columns: 2
        selected: root.choice === 1
        onClicked: root.picked(1)
        onHovered: root.hovered(1)
    }
}
