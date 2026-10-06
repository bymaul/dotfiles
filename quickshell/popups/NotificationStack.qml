import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components"
import "../services" as Services
Item {
    id: root
    required property var bar
    readonly property string focusedName: Hyprland.focusedMonitor?.name ?? ""
    readonly property var popupScreen: Services.Settings.popupScreen(Quickshell.screens, root.focusedName)
    readonly property var osdScreen: Services.Settings.mainScreen(Quickshell.screens)
    readonly property bool fsActive: {
        const scr = root.popupScreen;
        const tls = ToplevelManager.toplevels?.values ?? [];
        for (const t of tls) {
            if (!t || t.fullscreen !== true)
                continue;
            const onScreen = (t.screens ?? []).some(s => s && scr && s.name === scr.name);
            if (onScreen)
                return true;
        }
        return Hyprland.focusedWorkspace?.hasFullscreen === true;
    }
    PanelWindow {
        id: toastWin
        screen: root.popupScreen
        anchors {
            top: true
            right: true
        }
        margins.top: Services.Theme.popupTopGap
        margins.right: Services.Theme.popupMargin
        exclusiveZone: 0
        readonly property bool parked: root.bar.rightPopupBottom > 0
        readonly property int stackWidth: toastWin.parked ? root.bar.rightPopupWidth : Services.Theme.toastWidth
        readonly property int parkOffset: toastWin.parked ? root.bar.rightPopupBottom + Services.Theme.popupSpacing - Services.Theme.popupTopGap : 0
        implicitWidth: toastWin.stackWidth
        implicitHeight: toastWin.parkOffset + toastList.contentHeight
        visible: root.popupScreen !== null
        color: Services.Theme.transparent
        WlrLayershell.namespace: "qs-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        ListView {
            id: toastList
            anchors {
                left: parent.left
                right: parent.right
            }
            y: toastWin.parkOffset
            width: toastWin.stackWidth
            height: contentHeight
            clip: true
            interactive: false
            spacing: Services.Theme.popupSpacing
            model: Services.Notifs.toasts.filter(t => !Services.Notifs.isOsd(t) && (!root.fsActive || Services.Notifs.showInFullscreen(t)))
            delegate: ToastCard {
                required property var modelData
                notification: modelData
                width: toastWin.stackWidth
            }
        }
    }
    PanelWindow {
        id: osdWin
        screen: root.osdScreen
        anchors {
            bottom: true
        }
        margins.bottom: Services.Theme.osdBottomMargin
        exclusiveZone: 0
        implicitWidth: Services.Theme.osdWidth
        implicitHeight: osdList.contentHeight
        visible: osdList.count > 0 && root.osdScreen !== null
        color: Services.Theme.transparent
        WlrLayershell.namespace: "qs-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        ListView {
            id: osdList
            width: Services.Theme.osdWidth
            height: contentHeight
            clip: true
            interactive: false
            spacing: Services.Theme.popupSpacing
            model: Services.Notifs.toasts.filter(t => Services.Notifs.isOsd(t)).slice(0, 1)
            delegate: OsdCard {
                required property var modelData
                notification: modelData
            }
        }
    }
}
