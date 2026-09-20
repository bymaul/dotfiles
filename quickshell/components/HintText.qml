import QtQuick
import "../services" as Services
Text {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    color: Services.Theme.dim
    font.family: Services.Theme.font
    font.pixelSize: Services.Theme.px10
}
