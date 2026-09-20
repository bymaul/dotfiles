import QtQuick
import Quickshell.Hyprland
import "../services" as Services
Text {
    id: root
    anchors {
        left: workspaces.right
        leftMargin: 10
        verticalCenter: parent.verticalCenter
    }
    text: Hyprland.activeToplevel?.title ?? ""
    visible: text !== ""
    width: Math.min(implicitWidth, 420)
    color: Services.Theme.fg
    font.family: Services.Theme.font
    font.pixelSize: Services.Theme.px12
    elide: Text.ElideRight
    maximumLineCount: 1
}
