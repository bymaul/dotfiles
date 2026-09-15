import QtQuick
import "../Palette.js" as Palette
Item {
    id: root
    required property string glyph
    property color glyphColor: Palette.fg
    property int pixelSize: Palette.px13
    signal clicked
    implicitWidth: label.width
    implicitHeight: label.height
    width: label.width
    height: label.height
    Text {
        id: label
        text: root.glyph
        color: root.glyphColor
        font.family: Palette.font
        font.pixelSize: root.pixelSize
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
