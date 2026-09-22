import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services

// Slim bar for non-main monitors: per-monitor workspaces + title.
// Full controls stay on main Bar; popups/toasts follow the focused monitor.
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
    readonly property string slimName: slim.targetScreen && slim.targetScreen.name ? slim.targetScreen.name : ""
    Component.onCompleted: {
        if (slim.slimName !== "")
            Services.Settings.registerBar(slim.slimName, slim);
    }
    Component.onDestruction: Services.Settings.unregisterBar(slim)
    onSlimNameChanged: {
        Services.Settings.unregisterBar(slim);
        if (slim.slimName !== "")
            Services.Settings.registerBar(slim.slimName, slim);
    }
    Workspaces {
        id: workspaces
        screenName: slim.slimName
    }
    WindowTitle {
        screenName: slim.slimName
    }
}
