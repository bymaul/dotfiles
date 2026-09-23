import QtQuick
import "../services" as Services

// Shared 20x20 dismiss ("x") button for notification cards.
Item {
    id: root
    signal clicked()
    width: 20
    height: 20
    Text {
        anchors.centerIn: parent
        text: "󰅖"
        color: closeArea.containsMouse ? Services.Theme.fg : Services.Theme.dim
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px12
    }
    MouseArea {
        id: closeArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            mouse.accepted = true;
            root.clicked();
        }
    }
}
