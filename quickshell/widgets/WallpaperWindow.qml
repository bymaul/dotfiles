import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: -1
    color: Services.Theme.bg
    WlrLayershell.namespace: "wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    Image {
        anchors.fill: parent
        source: Services.Wallpaper.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        sourceSize.width: root.modelData?.width ?? 0
        sourceSize.height: root.modelData?.height ?? 0
    }
}
