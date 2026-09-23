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
            const name = (m && typeof m.name === "string" && m.name !== "") ? m.name : (typeof m === "string" ? m : "");
            return name === root.screenName;
        });
    }
    readonly property int activeId: {
        const mons = Hyprland.monitors && Hyprland.monitors.values ? Hyprland.monitors.values : [];
        for (const m of mons) {
            if (m && m.name === root.screenName && m.activeWorkspace)
                return m.activeWorkspace.id ?? -99999;
        }
        return -99999;
    }
    readonly property var slotIds: {
        const ids = new Set();
        for (const ws of root.pool ?? []) {
            if (ws && typeof ws.id === "number")
                ids.add(ws.id);
        }
        if (root.activeId !== -99999)
            ids.add(root.activeId);
        return [...ids].sort((a, b) => a - b);
    }
    function workspaceById(id: int): var {
        return root.wsById[id] ?? null;
    }
    readonly property var wsById: {
        const m = {};
        for (const ws of root.pool ?? []) {
            if (ws && typeof ws.id === "number")
                m[ws.id] = ws;
        }
        return m;
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
            readonly property bool isFocused: ws ? !!ws.active : modelData === root.activeId
            width: 25
            height: 25
            Rectangle {
                anchors.fill: parent
                color: isFocused ? Services.Theme.surface : Services.Theme.transparent
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
