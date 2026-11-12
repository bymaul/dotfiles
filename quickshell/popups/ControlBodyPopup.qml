import QtQuick
import Quickshell
import "../components"
import "../services" as Services
BasePopup {
    id: root
    required property var controlPanel
    useGrab: false
    extraTop: controlPanel.height + Services.Theme.popupSpacing
    implicitWidth: Services.Theme.popupWidth
    readonly property int calendarFixedHeight: calendarCard.fixedHeight
    implicitHeight: root.calendarFixedHeight
    visible: root.reanchoring ? false : controlPanel.visible
    property bool reanchoring: false
    property int lastPanelHeight: 0
    property var pendingBodyAnchor: null
    readonly property alias calendar: calendarCard
    required property var clock
    function close(): void {
        controlPanel.close();
    }
    function cancelOrClose(): void {
        root.controlPanel.handleEscape();
    }
    function quitAction(): void {
        root.controlPanel.handleEscape();
    }
    function reanchor(window): void {
        const curHeight = root.controlPanel.height;
        const screenChanged = !!window && root.anchor.window !== window;
        const heightChanged = curHeight !== root.lastPanelHeight;
        if (!screenChanged && !heightChanged && root.visible)
            return;
        root.lastPanelHeight = curHeight;
        root.wasVisible = true;
        if (screenChanged) {
            root.pendingBodyAnchor = window;
            root.reanchoring = true;
            bodyReanchorTimer.restart();
        } else if (heightChanged && root.visible) {
            root.reanchoring = true;
            bodyRepositionTimer.restart();
        }
    }
    Timer {
        id: bodyRepositionTimer
        interval: 1
        repeat: false
        onTriggered: root.reanchoring = false;
    }
    Timer {
        id: bodyReanchorTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (root.pendingBodyAnchor) {
                root.anchor.window = root.pendingBodyAnchor;
                root.pendingBodyAnchor = null;
            }
            root.reanchoring = false;
            root.wasVisible = false;
        }
    }
    Connections {
        target: root.controlPanel
        function onHeightChanged(): void {
            if (root.visible)
                reanchorTimer.restart();
        }
    }
    Timer {
        id: reanchorTimer
        interval: 10
        repeat: false
        onTriggered: {
            if (!root.visible)
                return;
            root.reanchor(root.anchor.window);
            root.controlPanel.forceGrab();
        }
    }
    onVisibleChanged: {
        if (root.reanchoring)
            return;
        if (visible && !wasVisible)
            calendarCard.resetToToday();
    }
    PanelNavKeys {
        host: root
        panel: root.controlPanel
    }
    Shortcut { sequence: "t"; enabled: root.visible && root.controlPanel.selectedKind() === "calendar"; onActivated: calendarCard.resetToToday() }
    Shortcut { sequence: "Shift+H"; enabled: root.visible && root.controlPanel.selectedKind() === "calendar"; onActivated: calendarCard.stepMonth(-1) }
    Shortcut { sequence: "Shift+L"; enabled: root.visible && root.controlPanel.selectedKind() === "calendar"; onActivated: calendarCard.stepMonth(1) }
    Shortcut { sequence: "Shift+K"; enabled: root.visible && root.controlPanel.selectedKind() === "calendar"; onActivated: calendarCard.stepMonth(-12) }
    Shortcut { sequence: "Shift+J"; enabled: root.visible && root.controlPanel.selectedKind() === "calendar"; onActivated: calendarCard.stepMonth(12) }
    Shortcut { sequence: "Shift+Left"; enabled: root.visible && root.controlPanel.selectedKind() === "calendar"; onActivated: calendarCard.stepMonth(-1) }
    Shortcut { sequence: "Shift+Right"; enabled: root.visible && root.controlPanel.selectedKind() === "calendar"; onActivated: calendarCard.stepMonth(1) }
    Shortcut { sequence: "Shift+Up"; enabled: root.visible && root.controlPanel.selectedKind() === "calendar"; onActivated: calendarCard.stepMonth(-12) }
    Shortcut { sequence: "Shift+Down"; enabled: root.visible && root.controlPanel.selectedKind() === "calendar"; onActivated: calendarCard.stepMonth(12) }
    Column {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        CalendarCard {
            id: calendarCard
            clock: root.clock
            popup: root.controlPanel
            focused: root.controlPanel.selectedKind() === "calendar"
        }
    }
}
