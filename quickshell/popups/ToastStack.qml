import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services" as Services
import "../Palette.js" as Palette

// Toast layer (replaces mako): top-right under the bar, newest first,
// at most 5 (capped by the Notifs service). Whitelisted in the
// panel's focus grab, so clicking a toast never closes popups.
PanelWindow {
    id: toastStack

    anchors {
        top: true
        right: true
    }

    // Top edge aligns with the anchored popups at y=40: layer-shell
    // margins stack AFTER the bar's 34px exclusive zone, so only
    // popupTopGap is needed (adding bar.height double-counts it).
    // Below an open right-side popup, park under it instead so
    // toasts never hide behind it. No animation: jumps at once.
    margins.top: toastStack.parked
        ? bar.rightPopupBottom + 8 : Palette.popupTopGap
    margins.right: Palette.popupMargin

    exclusiveZone: 0

    // Parked under an open right-side popup (panel width, edges
    // align), else narrow and floating at the popup top edge.
    readonly property bool parked: bar.rightPopupBottom > 0
    readonly property int stackWidth: toastStack.parked
        ? Palette.popupWidth : Palette.toastWidth

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
