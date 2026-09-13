import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6
    Repeater {
        model: SystemTray.items
        delegate: Item {
            id: trayIcon
            required property var modelData
            width: 18
            height: 18
            Image {
                anchors.fill: parent
                source: modelData.icon
                sourceSize.width: 18
                sourceSize.height: 18
                fillMode: Image.PreserveAspectFit
            }
            QsMenuAnchor {
                id: menuAnchor
                menu: trayIcon.modelData.menu
                anchor.item: trayIcon
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton && !trayIcon.modelData.onlyMenu)
                        trayIcon.modelData.activate();
                    else if (trayIcon.modelData.hasMenu)
                        menuAnchor.open();
                    else
                        trayIcon.modelData.secondaryActivate();
                }
            }
        }
    }
}
