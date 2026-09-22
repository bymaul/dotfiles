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
    required property string screenName
    readonly property var pool: {
        const all = Hyprland.workspaces && Hyprland.workspaces.values ? Hyprland.workspaces.values : [];
        return all.filter(ws => {
            if (!ws)
                return false;
            const m = ws.monitor;
            const name = m && m.name ? m.name : (typeof m === "string" ? m : "");
            return String(name) === root.screenName;
        });
    }
    readonly property var slotIds: {
        const ids = new Set([1, 2, 3]);
        for (const ws of root.pool ?? []) {
            if (ws && ws.id > 0)
                ids.add(ws.id);
        }
        return [...ids].sort((a, b) => a - b);
    }
    function workspaceById(id: int): var {
        const all = Hyprland.workspaces && Hyprland.workspaces.values ? Hyprland.workspaces.values : [];
        const hit = all.find(ws => ws && ws.id === id);
        return hit ? hit : null;
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
            readonly property bool isFocused: !!(ws && ws.active)
            width: 25
            height: 25
            Rectangle {
                anchors.fill: parent
                color: isFocused ? Services.Theme.surface : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: ws && ws.name ? ws.name : modelData
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
