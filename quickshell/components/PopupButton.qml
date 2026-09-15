import QtQuick
import "../Palette.js" as Palette
Rectangle {
    id: root
    required property string label
    property bool selected: false
    property bool accent: false
    property int columns: 2
    signal clicked
    width: (parent.width - (columns - 1) * Palette.popupSpacing) / columns
    height: Palette.rowHeight
    readonly property bool lit: root.accent || root.selected
    color: root.lit ? Palette.accent : hover.containsMouse ? Palette.hoverBg : Palette.surface
    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.lit ? Palette.onAccent : Palette.fg
        font.family: Palette.font
        font.pixelSize: Palette.px12
    }
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
