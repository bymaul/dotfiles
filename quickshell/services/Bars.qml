pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Singleton {
    id: bars

    property var barByScreen: ({})

    function registerBar(name: string, win: var): void {
        if (typeof name !== "string" || name === "" || !win)
            return;
        const next = Object.assign({}, bars.barByScreen);
        for (const k of Object.keys(next)) {
            if (next[k] === win && k !== name)
                delete next[k];
        }
        next[name] = win;
        bars.barByScreen = next;
    }
    function syncBar(win: var, name: string): void {
        bars.unregisterBar(win);
        if (typeof name === "string" && name !== "" && win)
            bars.registerBar(name, win);
    }
    function unregisterBar(win: var): void {
        if (!win)
            return;
        const next = Object.assign({}, bars.barByScreen);
        let changed = false;
        for (const k of Object.keys(next)) {
            if (next[k] === win) {
                delete next[k];
                changed = true;
            }
        }
        if (changed)
            bars.barByScreen = next;
    }
    function barForScreen(name: string): var {
        if (typeof name !== "string" || name === "")
            return null;
        return bars.barByScreen[name] ?? null;
    }
    property var anchorByScreen: ({})

    function registerAnchor(name: string, win: var): void {
        if (typeof name !== "string" || name === "" || !win)
            return;
        const next = Object.assign({}, bars.anchorByScreen);
        for (const k of Object.keys(next)) {
            if (next[k] === win && k !== name)
                delete next[k];
        }
        next[name] = win;
        bars.anchorByScreen = next;
    }
    function syncAnchor(win: var, name: string): void {
        bars.unregisterAnchor(win);
        if (typeof name === "string" && name !== "" && win)
            bars.registerAnchor(name, win);
    }
    function unregisterAnchor(win: var): void {
        if (!win)
            return;
        const next = Object.assign({}, bars.anchorByScreen);
        let changed = false;
        for (const k of Object.keys(next)) {
            if (next[k] === win) {
                delete next[k];
                changed = true;
            }
        }
        if (changed)
            bars.anchorByScreen = next;
    }
    function anchorForScreen(name: string): var {
        if (typeof name !== "string" || name === "")
            return null;
        return bars.anchorByScreen[name] ?? null;
    }

    function isSpecialWorkspace(ws): bool {
        if (!ws)
            return false;
        if (typeof ws === "string")
            return ws === "special" || ws.indexOf("special:") === 0;
        if (typeof ws !== "object")
            return false;
        if (typeof ws.id === "number" && ws.id < 0)
            return true;
        const n = ws.name;
        if (typeof n !== "string")
            return false;
        return n === "special" || n.indexOf("special:") === 0;
    }
    function isSpecialActive(name: string): bool {
        if (typeof name !== "string" || name === "")
            return false;
        const mon = (Hyprland.monitors?.values ?? []).find(m => m && m.name === name) ?? null;
        if (mon) {
            const sp = mon.lastIpcObject?.specialWorkspace;
            if (sp && typeof sp === "object") {
                if (typeof sp.id === "number")
                    return sp.id !== 0;
                if (typeof sp.name === "string")
                    return sp.name !== "";
            }
            if (mon.lastIpcObject)
                return false;
        }
        const wss = Hyprland.workspaces?.values ?? [];
        return wss.some(w => w && w.active === true && bars.isSpecialWorkspace(w) && w.monitor?.name === name);
    }
    function hasWlrFullscreen(name: string): bool {
        if (typeof name !== "string" || name === "")
            return false;
        const wtls = ToplevelManager.toplevels?.values ?? [];
        return wtls.some(t => t && t.fullscreen === true && (t.screens ?? []).some(s => s && s.name === name));
    }
    function matchFullscreen(name: string, specialOnly: bool): bool {
        if (typeof name !== "string" || name === "")
            return false;
        if (specialOnly && !bars.isSpecialActive(name))
            return false;
        if (!bars.hasWlrFullscreen(name))
            return false;
        const htls = Hyprland.toplevels?.values ?? [];
        return htls.some(t => {
            if (!t)
                return false;
            if (!(Number(t.lastIpcObject?.fullscreen ?? 0) >= 2))
                return false;
            const special = bars.isSpecialWorkspace(t.workspace) || bars.isSpecialWorkspace(t.lastIpcObject?.workspace);
            if (specialOnly && !special)
                return false;
            if (!specialOnly && special)
                return false;
            return t.monitor?.name === name || t.workspace?.monitor?.name === name;
        });
    }
    function isFullscreen(name: string): bool {
        return bars.matchFullscreen(name, false);
    }
    function isSpecialFullscreen(name: string): bool {
        return bars.matchFullscreen(name, true);
    }
    function isAnyFullscreen(name: string): bool {
        return bars.isFullscreen(name) || bars.isSpecialFullscreen(name);
    }
    readonly property bool anyWlrFullscreen: (ToplevelManager.toplevels?.values ?? []).some(t => t && t.fullscreen === true)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event?.name ?? "";
            const relevant = ["fullscreen", "workspace", "special", "openwindow", "closewindow", "movewindow", "focused"];
            if (relevant.some(k => n.indexOf(k) >= 0)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshMonitors();
                Hyprland.refreshWorkspaces();
            }
        }
    }
    Timer {
        interval: 1500
        running: bars.anyWlrFullscreen
        repeat: true
        onTriggered: {
            Hyprland.refreshToplevels();
            Hyprland.refreshMonitors();
        }
    }
    Component.onCompleted: {
        Hyprland.refreshToplevels();
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
    }
}
