import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../Palette.js" as Palette
PopupWindow {
    id: base
    required property var bar
    property string anchorMode: "right"
    property int extraTop: 0
    property bool useGrab: true
    property bool preventClose: false
    property var returnTo: null
    function regrab(): void {
        if (!grab.active && base.visible)
            grab.active = true;
    }
    function close(): void {
        const back = base.returnTo;
        base.returnTo = null;
        base.visible = false;
        if (back)
            back.visible = true;
    }
    anchor.window: bar
    anchor.rect.x: base.anchorMode === "center" ? bar.width / 2 - width / 2 : bar.width - width - Palette.popupMargin
    anchor.rect.y: bar.height + Palette.popupTopGap + base.extraTop
    visible: false
    color: "transparent"
    onVisibleChanged: {
        if (!base.visible)
            grab.active = false;
    }
    HyprlandFocusGrab {
        id: grab
        windows: [base]
        onCleared: {
            if (base.preventClose)
                base.regrab();
            else
                base.close();
        }
    }
    Timer {
        id: grabTimer
        interval: Palette.grabDelay
        running: base.visible && base.useGrab
        repeat: false
        onTriggered: grab.active = true
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged(): void {
            if (base.visible && base.useGrab) {
                grab.active = false;
                grabTimer.restart();
            }
        }
    }
    // A monitor mode/scale change destroys and recreates this window's
    // surface, which clears the focus grab. Re-assert it once the new
    // surface connects so keyboard focus is restored.
    Connections {
        target: base
        function onWindowConnected(): void {
            if (base.visible && base.useGrab && base.preventClose)
                base.regrab();
        }
    }
}
