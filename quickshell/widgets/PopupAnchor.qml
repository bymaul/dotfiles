import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services

PanelWindow {
    id: anchor
    required property var targetScreen
    screen: anchor.targetScreen
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 1
    readonly property string anchorName: anchor.targetScreen?.name ?? ""
    readonly property bool screenFullscreen: Services.Bars.isAnyFullscreen(anchor.anchorName)
    exclusiveZone: anchor.screenFullscreen ? -1 : 0
    color: Services.Theme.transparent
    WlrLayershell.namespace: "qs-popup-anchor"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Component.onCompleted: Services.Bars.syncAnchor(anchor, anchor.anchorName)
    Component.onDestruction: Services.Bars.unregisterAnchor(anchor)
    onAnchorNameChanged: Services.Bars.syncAnchor(anchor, anchor.anchorName)
}
