import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../services" as Services
PopupWindow {
    id: base
    required property var bar
    property string anchorMode: "right"
    property int extraTop: 0
    property bool useGrab: true
    property bool preventClose: false
    // Busy protocol for popups that apply async changes (e.g. monitors):
    // call kickBusy() when a change starts and on each progress signal.
    // While preventClose is set the grab is kept and outside clicks re-grab
    // instead of closing; it auto-clears busyMs after the last kick.
    property int busyMs: 1500
    function kickBusy(): void {
        base.preventClose = true;
        base.regrab();
        busySettle.restart();
    }
    function calmBusy(): void {
        busySettle.stop();
        base.preventClose = false;
    }
    property var returnTo: null
    property var extraGrabWindows: []
    readonly property var effectiveGrabWindows: [base].concat(extraGrabWindows ?? [])
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
    function escArmed(): bool {
        return true;
    }
    function quitArmed(): bool {
        return true;
    }
    function cancelOrClose(): void {
        base.close();
    }
    function stepListView(view, dir: int, stride: int): void {
        if (!view || view.count === 0)
            return;
        view.currentIndex = Services.Theme.clamp(view.currentIndex + dir * (stride ?? 1), 0, view.count - 1);
        view.positionViewAtIndex(view.currentIndex, ListView.Contain);
    }
    function clampListView(view): void {
        if (!view)
            return;
        if (view.currentIndex >= view.count)
            view.currentIndex = Math.max(0, view.count - 1);
    }
    function selectInList(view, i: int): void {
        if (!view)
            return;
        view.currentIndex = Services.Theme.clamp(i, 0, Math.max(0, view.count - 1));
        view.positionViewAtIndex(view.currentIndex, ListView.Contain);
    }
    Shortcut {
        sequence: "Escape"
        enabled: base.visible && base.escArmed()
        onActivated: base.cancelOrClose()
    }
    Shortcut {
        sequence: "q"
        enabled: base.visible && base.quitArmed()
        onActivated: base.close()
    }
    anchor.window: bar
    readonly property var anchorBar: base.anchor.window ?? bar
    readonly property real anchorBarWidth: anchorBar && anchorBar.width ? anchorBar.width : (bar && bar.width ? bar.width : 0)
    readonly property real anchorBarHeight: anchorBar && anchorBar.height ? anchorBar.height : (bar && bar.height ? bar.height : 0)
    readonly property real popupScreenHeight: base.screen && base.screen.height ? base.screen.height : Screen.height
    anchor.rect.x: (base.anchorMode === "center" || base.anchorMode === "middle") ? anchorBarWidth / 2 - width / 2 : anchorBarWidth - width - Services.Theme.popupMargin
    anchor.rect.y: base.anchorMode === "middle" ? Math.max(anchorBarHeight + Services.Theme.popupTopGap, popupScreenHeight / 2 - height / 2) : anchorBarHeight + Services.Theme.popupTopGap + base.extraTop
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
        windows: base.effectiveGrabWindows
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
        interval: Services.Theme.grabDelay
        running: false
        repeat: false
        onTriggered: grab.active = true
    }
    Timer {
        id: busyKeep
        interval: 200
        repeat: true
        running: base.preventClose && base.visible
        onTriggered: base.regrab()
    }
    Timer {
        id: busySettle
        interval: base.busyMs
        repeat: false
        onTriggered: {
            base.preventClose = false;
            if (base.visible)
                base.regrab();
        }
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
