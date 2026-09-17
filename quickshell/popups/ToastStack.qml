import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services" as Services
import "../Palette.js" as Palette
PanelWindow {
    id: root
    required property var bar
    screen: root.bar.mainScreen
    anchors {
        top: true
        right: true
    }
    margins.top: Palette.popupTopGap
    margins.right: Palette.popupMargin
    exclusiveZone: 0
    readonly property bool parked: root.bar.rightPopupBottom > 0
    readonly property int stackWidth: root.parked ? root.bar.rightPopupWidth : Palette.toastWidth
    readonly property int parkOffset: root.parked ? root.bar.rightPopupBottom + Palette.popupSpacing - Palette.popupTopGap : 0
    implicitWidth: root.stackWidth
    implicitHeight: root.parkOffset + toastList.contentHeight
    visible: true
    color: "transparent"
    WlrLayershell.namespace: "qs-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    ListView {
        id: toastList
        anchors {
            left: parent.left
            right: parent.right
        }
        y: root.parkOffset
        width: root.stackWidth
        height: contentHeight
        clip: true
        interactive: false
        spacing: Palette.popupSpacing
        model: Services.Notifs.toasts
        delegate: ToastCard {
            required property var modelData
            notification: modelData
            width: root.stackWidth
        }
    }
}
