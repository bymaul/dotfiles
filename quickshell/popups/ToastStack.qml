import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services" as Services
import "../Palette.js" as Palette

PanelWindow {
    id: toastStack

    anchors {
        top: true
        right: true
    }

    // Layer-shell margins stack AFTER the bar's exclusive zone:
    // only popupTopGap here, adding bar.height double-counts it.
    margins.top: toastStack.parked ? bar.rightPopupBottom + 8 : Palette.popupTopGap
    margins.right: Palette.popupMargin

    exclusiveZone: 0

    readonly property bool parked: bar.rightPopupBottom > 0
    readonly property int stackWidth: toastStack.parked ? Palette.popupWidth : Palette.toastWidth

    implicitWidth: toastStack.stackWidth
    implicitHeight: toastColumn.height

    visible: Services.Notifs.toasts.length > 0

    color: "transparent"

    WlrLayershell.namespace: "qs-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: toastColumn

        anchors {
            top: parent.top
            right: parent.right
        }

        width: toastStack.stackWidth
        spacing: Palette.popupSpacing

        Repeater {
            model: Services.Notifs.toasts

            delegate: ToastCard {
                required property var modelData

                notification: modelData
                width: toastStack.stackWidth
                parked: toastStack.parked
            }
        }
    }
}
