import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services

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
    readonly property string slimName: slim.targetScreen?.name ?? ""
    Component.onCompleted: Services.Bars.syncBar(slim, slim.slimName)
    Component.onDestruction: Services.Bars.unregisterBar(slim)
    onSlimNameChanged: Services.Bars.syncBar(slim, slim.slimName)
    MonitorHeader {
        screenName: slim.slimName
    }
}
