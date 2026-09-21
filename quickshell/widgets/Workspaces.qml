import QtQuick
import Quickshell.Hyprland
import "../services" as Services
Row {
    id: root
    anchors {
        left: parent.left
        leftMargin: Services.Theme.popupMargin
        verticalCenter: parent.verticalCenter
    }
    spacing: 4
    property string screenName: ""
    readonly property var pool: {
        const all = Hyprland.workspaces?.values ?? [];
        if (root.screenName === "")
            return all;
        return all.filter(ws => ws && String(ws.monitor?.name ?? ws.monitor ?? "") === root.screenName);
    }
    readonly property var slotIds: {
        const ids = new Set(root.screenName === "" ? [1, 2, 3] : []);
        for (const ws of root.pool ?? []) {
            if (ws && ws.id > 0)
                ids.add(ws.id);
        }
        const focused = Hyprland.focusedWorkspace?.id ?? 1;
        if (typeof focused === "number" && focused > 0 && root.screenName === "")
            ids.add(focused);
        return [...ids].sort((a, b) => a - b);
    }
    function workspaceById(id: int): var {
        return (Hyprland.workspaces?.values ?? []).find(ws => ws && ws.id === id) ?? null;
    }
    function activateSlot(id: int): void {
        const target = workspaceById(id);
        if (target && typeof target.activate === "function") {
            target.activate();
            return;
        }
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else
            Hyprland.dispatch("workspace " + String(id));
    }
    Repeater {
        model: slotIds
        delegate: Item {
            required property var modelData
            readonly property var ws: workspaceById(modelData)
            readonly property bool isFocused: root.screenName === "" ? modelData === (Hyprland.focusedWorkspace?.id ?? -1) : (ws?.active ?? false)
            width: 25
            height: 25
            Rectangle {
                anchors.fill: parent
                color: isFocused ? Services.Theme.surface : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: ws?.name || modelData
                color: isFocused ? Services.Theme.white : Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: activateSlot(modelData)
            }
        }
    }
}
