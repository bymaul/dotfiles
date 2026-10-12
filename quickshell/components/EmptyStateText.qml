import QtQuick
import "../services" as Services

Text {
    anchors.centerIn: parent
    color: Services.Theme.dim
    font.family: Services.Theme.font
    font.pixelSize: Services.Theme.px12
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
}
