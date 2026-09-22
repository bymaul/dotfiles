import QtQuick
import Quickshell.Hyprland
import "../services" as Services
Text {
    id: root
    required property string screenName
    anchors {
        left: workspaces.right
        leftMargin: 10
        verticalCenter: parent.verticalCenter
    }
    readonly property string activeTitle: {
        const all = Hyprland.toplevels && Hyprland.toplevels.values ? Hyprland.toplevels.values : [];
        for (const t of all) {
            if (t && t.activated) {
                const m = t.monitor;
                const name = m && m.name ? m.name : "";
                if (String(name) === root.screenName)
                    return t.title ?? "";
            }
        }
        const active = Hyprland.activeToplevel;
        if (active) {
            const m = active.monitor;
            const name = m && m.name ? m.name : "";
            if (String(name) === root.screenName)
                return active.title ?? "";
        }
        return "";
    }
    text: root.activeTitle
    visible: text !== ""
    width: Math.min(implicitWidth, 420)
    color: Services.Theme.fg
    font.family: Services.Theme.font
    font.pixelSize: Services.Theme.px12
    elide: Text.ElideRight
    maximumLineCount: 1
}
