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
    property Item focusTarget: null
    property double openedAt: 0
    function focusTargetNow(): void {
        if (base.focusTarget && base.visible)
            base.focusTarget.forceActiveFocus();
    }
    function regrab(): void {
        if (!grab.active && base.visible)
            grab.active = true;
    }
    function kickGrab(): void {
        if (base.visible && base.useGrab)
            grabTimer.restart();
    }
    function close(): void {
        const hadGrab = grab.active;
        const back = base.returnTo;
        base.returnTo = null;
        base.visible = false;
        if (back) {
            back.visible = true;
            if (hadGrab && back.useGrab !== false && typeof back.regrab === "function")
                back.regrab();
        }
    }
    anchor.window: bar
    anchor.rect.x: (base.anchorMode === "center" || base.anchorMode === "middle") ? bar.width / 2 - width / 2 : bar.width - width - Palette.popupMargin
    anchor.rect.y: base.anchorMode === "middle" ? Math.max(bar.height + Palette.popupTopGap, Screen.height / 2 - height / 2) : bar.height + Palette.popupTopGap + base.extraTop
    visible: false
    color: "transparent"
    onVisibleChanged: {
        if (!base.visible) {
            grab.active = false;
            grabTimer.stop();
            focusRetry.stop();
        } else {
            base.openedAt = Date.now();
            base.kickGrab();
            base.focusTargetNow();
        }
    }
    HyprlandFocusGrab {
        id: grab
        windows: [base]
        onActiveChanged: {
            if (grab.active && base.visible) {
                base.focusAttempts = 0;
                base.focusTargetNow();
                if (base.focusTarget && !base.focusTarget.activeFocus)
                    focusRetry.restart();
            } else {
                focusRetry.stop();
            }
        }
        onCleared: {
            if (!base.visible)
                return;
            if (base.preventClose) {
                base.regrab();
                return;
            }
            if (Date.now() - base.openedAt < 250) {
                base.regrab();
                return;
            }
            base.close();
        }
    }
    property int focusAttempts: 0
    Timer {
        id: focusRetry
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            if (!base.visible || !grab.active || !base.focusTarget) {
                base.focusAttempts = 0;
                return;
            }
            if (base.focusTarget.activeFocus) {
                base.focusAttempts = 0;
                return;
            }
            if (base.focusAttempts >= 5) {
                base.focusAttempts = 0;
                return;
            }
            base.focusAttempts += 1;
            base.focusTargetNow();
            focusRetry.restart();
        }
    }
    Timer {
        id: grabTimer
        interval: Palette.grabDelay
        running: false
        repeat: false
        onTriggered: grab.active = true
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged(): void {
            if (base.visible && base.useGrab) {
                grab.active = false;
                base.kickGrab();
            }
        }
    }
    Connections {
        target: base
        function onWindowConnected(): void {
            if (base.visible && base.useGrab)
                base.kickGrab();
        }
    }
}
