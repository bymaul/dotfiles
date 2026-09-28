import QtQuick
import "../services" as Services

// Shared forget/delete affordance for device rows (Wifi, Bluetooth).
// Visibility is controlled by the caller via the built-in visible prop.
Text {
    id: root
    required property bool selected
    signal forget()
    anchors.verticalCenter: parent.verticalCenter
    width: 24
    horizontalAlignment: Text.AlignHCenter
    text: "󰅖"
    color: root.selected ? Services.Theme.accentFg : forgetArea.containsMouse ? Services.Theme.fg : Services.Theme.dim
    font.family: Services.Theme.font
    font.pixelSize: Services.Theme.px13
    MouseArea {
        id: forgetArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            mouse.accepted = true;
            root.forget();
        }
    }
}
