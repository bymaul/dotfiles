import QtQuick
import Quickshell.Hyprland
import "../services" as Services
Row {
    id: root
    anchors {
        horizontalCenter: parent.horizontalCenter
        verticalCenter: parent.verticalCenter
    }
    spacing: Services.Theme.listSpacing
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
    readonly property var _slots: {
        const m = {};
        const ids = new Set();
        for (const ws of root.pool ?? []) {
            if (ws && typeof ws.id === "number") {
                ids.add(ws.id);
                m[ws.id] = ws;
            }
        }
        if (root.activeId !== -99999)
            ids.add(root.activeId);
        return {ids: [...ids].sort((a, b) => a - b), byId: m};
    }
    readonly property var slotIds: root._slots.ids
    function workspaceById(id: int): var {
        return (root.wsById ?? {})[id] ?? null;
    }
    readonly property var wsById: root._slots.byId
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
    function stepSlot(dir: int): void {
        const ids = root.slotIds ?? [];
        if (ids.length === 0)
            return;
        let i = ids.indexOf(root.activeId);
        if (i < 0)
            i = dir > 0 ? -1 : 0;
        root.activateSlot(ids[(i + dir + ids.length) % ids.length]);
    }
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y > 0)
                root.stepSlot(-1);
            else if (event.angleDelta.y < 0)
                root.stepSlot(1);
            event.accepted = true;
        }
    }
    Repeater {
        model: slotIds
        delegate: Item {
            required property var modelData
            readonly property var ws: workspaceById(modelData)
            readonly property bool isFocused: ws ? !!ws.active : modelData === root.activeId
            width: 22
            height: 25
            Text {
                anchors.centerIn: parent
                text: ws && ws.name ? ws.name : modelData
                color: isFocused ? Services.Theme.white : Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
                font.bold: isFocused
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: activateSlot(modelData)
            }
        }
    }
}
