import QtQuick
import Quickshell.Wayland
import "../services" as Services
Text {
    id: root
    required property string screenName
    property var leftItem: null
    anchors {
        left: root.leftItem ? root.leftItem.right : parent.left
        leftMargin: root.leftItem ? Services.Theme.titleMargin : Services.Theme.barMargin
        verticalCenter: parent.verticalCenter
    }
    readonly property string activeTitle: {
        const active = ToplevelManager.activeToplevel;
        if (active && active.activated && (active.screens ?? []).some(s => s && s.name === root.screenName))
            return active.title ?? "";
        return "";
    }
    text: root.activeTitle
    visible: text !== ""
    width: Math.min(implicitWidth, Services.Theme.titleMax)
    color: Services.Theme.fg
    font.family: Services.Theme.font
    font.pixelSize: Services.Theme.px12
    elide: Text.ElideRight
    maximumLineCount: 1
}
