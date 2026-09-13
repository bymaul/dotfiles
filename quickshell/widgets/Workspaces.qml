import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../Palette.js" as Palette

Row {
    anchors {
        left: parent.left
        leftMargin: 10
        verticalCenter: parent.verticalCenter
    }

    spacing: 4

    // Fixed slots 1..3 plus every workspace that currently exists
    // (occupied or persistent) plus the focused one; the strip only
    // ever shows real workspaces, never guesses.
    readonly property var slotIds: {
        const ids = new Set([1, 2, 3]);

        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0)
                ids.add(ws.id);
        }

        const focused = Hyprland.focusedWorkspace?.id ?? 1;

        if (typeof focused === "number" && focused > 0)
            ids.add(focused);

        return [...ids].sort((a, b) => a - b);
    }

    function workspaceById(id: int): var {
        return Hyprland.workspaces.values.find(ws => ws.id === id) ?? null;
    }

    function activateSlot(id: int): void {
        const ws = workspaceById(id);

        if (ws) {
            ws.activate();
            return;
        }

        // Empty slot: no object to activate. Mirror the Super+1..9
        // keybinds (hyprland.lua), which focus via the Lua API.
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

                radius: 0

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
