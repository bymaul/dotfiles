import QtQuick
import "../Palette.js" as Palette
Text {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    color: Palette.dim
    font.family: Palette.font
    font.pixelSize: Palette.px10
}
