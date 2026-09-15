import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../Palette.js" as Palette
Row {
    anchors {
        left: parent.left
        leftMargin: Palette.popupMargin
        verticalCenter: parent.verticalCenter
    }
    spacing: 4
    readonly property var slotIds: {
        const ids = new Set([1, 2, 3]);
        for (const ws of Hyprland.workspaces?.values ?? []) {
            if (ws && ws.id > 0)
                ids.add(ws.id);
        }
        const focused = Hyprland.focusedWorkspace?.id ?? 1;
        if (typeof focused === "number" && focused > 0)
            ids.add(focused);
        return [...ids].sort((a, b) => a - b);
    }
    function workspaceById(id: int): var {
        return (Hyprland.workspaces?.values ?? []).find(ws => ws && ws.id === id) ?? null;
    }
    function activateSlot(id: int): void {
        const ws = workspaceById(id);
        if (ws)
            ws.activate();
        else
            Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({workspace = ${id}})`]);
    }
    Repeater {
        model: slotIds
        delegate: Item {
            required property var modelData
            readonly property var ws: workspaceById(modelData)
            readonly property bool isFocused: modelData === (Hyprland.focusedWorkspace?.id ?? -1)
            width: 25
            height: 25
            Rectangle {
                anchors.fill: parent
                color: isFocused ? Palette.surface : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: ws?.name || modelData
                color: isFocused ? Palette.white : Palette.dim
                font.family: Palette.font
                font.pixelSize: Palette.px12
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: activateSlot(modelData)
            }
        }
    }
}
