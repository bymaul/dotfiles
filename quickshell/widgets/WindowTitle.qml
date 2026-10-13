import QtQuick
import Quickshell.Hyprland
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
        if (!active || !active.activated)
            return "";
        if (Services.Bars.isSpecialWorkspace(Services.Bars.hyprWorkspaceFor(active)))
            return "";
        if ((active.screens ?? []).some(s => s && s.name === root.screenName))
            return active.title ?? "";
        return "";
    }
    readonly property string specialTag: {
        const n = Services.Bars.specialName(root.screenName);
        return n !== "" ? "[" + n + "]" : "";
    }
    readonly property string specialTitle: {
        if (root.specialTag === "")
            return "";
        const ht = Hyprland.activeToplevel;
        const hw = ht?.workspace;
        if (!ht || !Services.Bars.isSpecialWorkspace(hw))
            return "";
        if (hw.name !== Services.Bars.specialFullName(root.screenName))
            return "";
        return ht.title ?? "";
    }
    text: {
        if (root.specialTag === "")
            return root.activeTitle;
        if (root.specialTitle === "")
            return root.specialTag;
        return root.specialTag + " " + root.specialTitle;
    }
    visible: text !== ""
    width: Math.min(implicitWidth, Services.Theme.titleMax)
    color: Services.Theme.fg
    font.family: Services.Theme.font
    font.pixelSize: Services.Theme.px12
    elide: Text.ElideRight
    maximumLineCount: 1
}
