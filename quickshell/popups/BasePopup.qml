import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../Palette.js" as Palette

// Shared base for all bar popups: anchored under the bar with a
// deferred focus grab and a transparent background.
//
// anchorMode "right" (default) docks top-right under the bar,
// "center" centers horizontally. extraTop shifts the popup down
// (the history companion parks below the control panel).
//
// useGrab false is for windows covered by the bar-level grab
// (control panel + history companion): a grab owned here would
// read clicks on the companion window as outside clicks and
// close everything. The grab object still exists but is never
// activated, so it stays a no-op.
PopupWindow {
    id: base

    required property var bar
    property string anchorMode: "right"
    property int extraTop: 0
    property bool useGrab: true

    anchor.window: bar

    anchor.rect.x: base.anchorMode === "center"
        ? bar.width / 2 - width / 2
        : bar.width - width - Palette.popupMargin
    anchor.rect.y: bar.height + Palette.popupTopGap + base.extraTop

    visible: false

    color: "transparent"

    HyprlandFocusGrab {
        id: grab

        windows: [base]

        // No grabFocus: it dismisses on any grab break (e.g. toast
        // expiry). Assert active from the timer, not bound to visible.
        onCleared: base.visible = false
    }

    Timer {
        interval: 100
        running: base.visible && base.useGrab
        repeat: false

        onTriggered: grab.active = true
    }
}
