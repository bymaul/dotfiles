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
            width: 15
            height: 15
            Image {
                anchors.fill: parent
                source: modelData?.icon ?? ""
                sourceSize.width: 15
                sourceSize.height: 15
                fillMode: Image.PreserveAspectFit
                cache: true
                asynchronous: true
                visible: (modelData?.icon ?? "") !== ""
            }
            QsMenuAnchor {
                id: menuAnchor
                menu: trayIcon.modelData?.menu ?? null
                anchor.item: trayIcon
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const item = trayIcon.modelData;
                    if (!item)
                        return;
                    try {
                        if (mouse.button === Qt.LeftButton && !item.onlyMenu)
                            item.activate();
                        else if (item.hasMenu)
                            menuAnchor.open();
                        else
                            item.secondaryActivate();
                    } catch (_) {}
                }
            }
        }
    }
}
