import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../Palette.js" as Palette

// Shared popup base: anchored under the bar, deferred focus grab.
// useGrab false (panel + history companion) leaves the grab object
// present but never activated: an owned grab would read clicks on
// the companion window as outside clicks and close everything.
PopupWindow {
    id: base

    required property var bar
    property string anchorMode: "right"
    property int extraTop: 0
    property bool useGrab: true

    anchor.window: bar

    anchor.rect.x: base.anchorMode === "center" ? bar.width / 2 - width / 2 : bar.width - width - Palette.popupMargin
    anchor.rect.y: bar.height + Palette.popupTopGap + base.extraTop

    visible: false

    color: "transparent"

    // Release explicitly on hide: if the window closes while grab
    // creation is still in flight, the compositor may never clear
    // it and keyboard focus stays stuck on a hidden window.
    onVisibleChanged: {
        if (!base.visible)
            grab.active = false
    }

    HyprlandFocusGrab {
        id: grab

        windows: [base]

        // Never bind active to visible: asserting it in the show
        // frame leaves the grab dead; the timer below defers it.
        onCleared: base.visible = false
    }

    Timer {
        interval: 100
        running: base.visible && base.useGrab
        repeat: false

        onTriggered: grab.active = true
    }
}
