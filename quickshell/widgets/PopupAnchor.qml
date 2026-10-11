import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services

// Invisible per-screen anchor that lifts bar popups into the Overlay layer.
// The bar itself stays in Top (hidden by fullscreen), while PopupWindows
// anchored here render above fullscreen windows. Always mapped and fully
// transparent; the qs-popup-anchor layer rule keeps it click-through.
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
    exclusiveZone: 0
    color: Services.Theme.transparent
    WlrLayershell.namespace: "qs-popup-anchor"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    readonly property string anchorName: anchor.targetScreen?.name ?? ""
    Component.onCompleted: Services.Bars.syncAnchor(anchor, anchor.anchorName)
    Component.onDestruction: Services.Bars.unregisterAnchor(anchor)
    onAnchorNameChanged: Services.Bars.syncAnchor(anchor, anchor.anchorName)
}
