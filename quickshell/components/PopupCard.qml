import QtQuick
import "../services" as Services
Rectangle {
    id: root
    anchors.fill: parent
    default property alias content: column.data
    color: Services.Theme.bg
    Column {
        id: column
        anchors.fill: parent
        anchors.margins: Services.Theme.popupPadding
        spacing: Services.Theme.popupSpacing
    }
}
