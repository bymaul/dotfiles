import QtQuick
import "../Palette.js" as Palette
Rectangle {
    id: root
    anchors.fill: parent
    default property alias content: column.data
    color: Palette.bg
    Column {
        id: column
        anchors.fill: parent
        anchors.margins: Palette.popupPadding
        spacing: Palette.popupSpacing
    }
}
