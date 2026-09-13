import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services" as Services
import "../Palette.js" as Palette
PanelWindow {
    id: root
    anchors {
        top: true
        right: true
    }
    margins.top: root.parked ? bar.rightPopupBottom + Palette.popupSpacing : Palette.popupTopGap
    margins.right: Palette.popupMargin
    exclusiveZone: 0
    readonly property bool parked: bar.rightPopupBottom > 0
    readonly property int stackWidth: root.parked ? Palette.popupWidth : Palette.toastWidth
    implicitWidth: root.stackWidth
    implicitHeight: column.height
    visible: Services.Notifs.toasts.length > 0
    color: "transparent"
    WlrLayershell.namespace: "qs-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    Column {
        id: column
        anchors {
            top: parent.top
            right: parent.right
        }
        width: root.stackWidth
        spacing: Palette.popupSpacing
        Repeater {
            model: Services.Notifs.toasts
            delegate: ToastCard {
                required property var modelData
                notification: modelData
                width: root.stackWidth
                parked: root.parked
            }
        }
    }
}
