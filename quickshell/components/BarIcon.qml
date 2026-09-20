import QtQuick
import "../services" as Services
Item {
    id: root
    required property string glyph
    property color glyphColor: Services.Theme.fg
    property int pixelSize: Services.Theme.px13
    signal clicked
    implicitWidth: label.width
    implicitHeight: label.height
    width: label.width
    height: label.height
    Text {
        id: label
        text: root.glyph
        color: root.glyphColor
        font.family: Services.Theme.font
        font.pixelSize: root.pixelSize
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
