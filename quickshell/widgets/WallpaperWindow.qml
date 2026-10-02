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

    property int fadeMs: 350
    property real zoomFrom: 1.04
    property string current: Services.Wallpaper.source

    onCurrentChanged: {
        if (root.current === "")
            return;
        if (bottom.source.toString() === "" && top.source.toString() === "") {
            bottom.source = root.current;
            return;
        }
        if (root.current === bottom.source.toString())
            return;
        crossfade.stop();
        top.opacity = 0;
        top.source = root.current;
    }

    Image {
        id: bottom
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        opacity: 0
        sourceSize.width: root.modelData?.width ?? 0
        sourceSize.height: root.modelData?.height ?? 0
        onStatusChanged: {
            if (status === Image.Ready && opacity === 0 && top.source.toString() === "")
                startupFade.restart();
        }
    }

    Image {
        id: top
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        opacity: 0
        scale: root.zoomFrom
        transformOrigin: Item.Center
        sourceSize.width: root.modelData?.width ?? 0
        sourceSize.height: root.modelData?.height ?? 0
        onStatusChanged: {
            if (status === Image.Ready && source.toString() !== "" && source.toString() !== bottom.source.toString())
                crossfade.restart();
        }
    }

    ParallelAnimation {
        id: startupFade
        NumberAnimation {
            target: bottom
            property: "opacity"
            from: 0
            to: 1
            duration: root.fadeMs
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: bottom
            property: "scale"
            from: root.zoomFrom
            to: 1.0
            duration: root.fadeMs
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: crossfade
        NumberAnimation {
            target: top
            property: "opacity"
            from: 0
            to: 1
            duration: root.fadeMs
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: top
            property: "scale"
            from: root.zoomFrom
            to: 1.0
            duration: root.fadeMs
            easing.type: Easing.OutCubic
        }
        onFinished: {
            bottom.source = top.source;
            bottom.opacity = 1;
            bottom.scale = 1.0;
            top.opacity = 0;
            top.scale = root.zoomFrom;
            top.source = "";
        }
    }

    Component.onCompleted: {
        if (root.current !== "")
            bottom.source = root.current;
    }
}
