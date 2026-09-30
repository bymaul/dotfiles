import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services" as Services

PanelWindow {
    id: bar

    required property var lockContext
    required property var sessionLock
    required property var screenshotTool

    anchors {
        top: true
        left: true
        right: true
    }

    readonly property string focusedName: Hyprland.focusedMonitor?.name ?? ""
    property var mainScreen: Services.Settings.mainScreen(Quickshell.screens)
    screen: bar.mainScreen ?? Quickshell.screens[0] ?? null
    readonly property string mainName: bar.mainScreen?.name ?? ""

    function currentPopupAnchor(): var {
        return Services.Bars.barForScreen(bar.focusedName) ?? bar;
    }
    function syncBarReg(): void {
        Services.Bars.syncBar(bar, bar.mainName);
    }
    Component.onCompleted: bar.syncBarReg()
    Component.onDestruction: Services.Bars.unregisterBar(bar)
    onMainNameChanged: bar.syncBarReg()

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

    readonly property var historyPanel: popups.historyPanel
    readonly property int rightPopupBottom: popups.rightPopupBottom
    readonly property int rightPopupWidth: popups.rightPopupWidth
    function popupByName(name: string): var { return popups.popupByName(name); }
    function closePopups(): void { popups.closePopups(); }
    function togglePopup(name: string): void { popups.togglePopup(name); }
    function openFromPanel(name: string): void { popups.openFromPanel(name); }
    function openExclusive(target, returnTo = null): void { popups.openExclusive(target, returnTo); }
    function revealHistory(i: int): void { popups.revealHistory(i); }
    function followPopupAnchor(): void { popups.followPopupAnchor(bar.currentPopupAnchor()); }

    function lockScreen(): void {
        bar.closePopups();
        if (lockContext && typeof lockContext.reset === "function")
            lockContext.reset();
        if (sessionLock)
            sessionLock.locked = true;
    }
    function handlePowerKey(): void {
        Services.Power.lock();
        bar.closePopups();
        Quickshell.execDetached(["systemctl", "suspend", "-i"]);
    }
    function screenshot(mode: string): void {
        screenshotTool.capture(mode);
    }
    function unlocked(): bool {
        return !(bar.sessionLock && bar.sessionLock.locked === true);
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged(): void { bar.followPopupAnchor(); }
    }
    Connections {
        target: Services.Bars
        function onBarByScreenChanged(): void { bar.followPopupAnchor(); }
    }
    onFocusedNameChanged: bar.followPopupAnchor()
    onScreenChanged: bar.followPopupAnchor()
    readonly property int screenCount: Quickshell.screens.length
    onScreenCountChanged: {
        bar.followPopupAnchor();
        Services.Settings.refreshMonitors(true);
    }

    DepCheck {}

    MonitorHeader {
        screenName: bar.mainName
    }
    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }
    Row {
        id: systemStatus
        anchors {
            right: parent.right
            rightMargin: Services.Theme.barMargin
            verticalCenter: parent.verticalCenter
        }
        spacing: Services.Theme.groupSpacing
        Tray {}
        SystemGroup {
            bar: bar
        }
        BatteryIcon {
            bar: bar
        }
        BellIcon {
            bar: bar
        }
        Clock {
            bar: bar
            clockSource: systemClock
        }
    }

    BarPopups {
        id: popups
        bar: bar
        clock: systemClock
    }
    BarShortcuts {
        bar: bar
    }
}
