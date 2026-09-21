import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services

// Slim bar for non-main monitors: workspaces live here, popups stay on main.
PanelWindow {
    id: slim
    required property var targetScreen
    screen: slim.targetScreen
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Services.Theme.barHeight
    exclusiveZone: implicitHeight
    color: Services.Theme.barBg
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: Services.Theme.border
    }
    WlrLayershell.namespace: "qs-bar"
    Workspaces {
        id: workspaces
        screenName: slim.targetScreen && slim.targetScreen.name ? slim.targetScreen.name : ""
    }
    WindowTitle {}
}
