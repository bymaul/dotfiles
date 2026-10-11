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

    function isFullscreen(name: string): bool {
        if (typeof name !== "string" || name === "")
            return false;
        const wtls = ToplevelManager.toplevels?.values ?? [];
        const wlr = wtls.some(t => t && t.fullscreen === true && (t.screens ?? []).some(s => s && s.name === name));
        if (!wlr)
            return false;
        const htls = Hyprland.toplevels?.values ?? [];
        return htls.some(t => {
            if (!t)
                return false;
            if (!(Number(t.lastIpcObject?.fullscreen ?? 0) >= 2))
                return false;
            return t.monitor?.name === name || t.workspace?.monitor?.name === name;
        });
    }
    readonly property bool anyWlrFullscreen: (ToplevelManager.toplevels?.values ?? []).some(t => t && t.fullscreen === true)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event?.name ?? "";
            const relevant = ["fullscreen", "workspace", "openwindow", "closewindow", "movewindow", "focused"];
            if (relevant.some(k => n.indexOf(k) >= 0))
                Hyprland.refreshToplevels();
        }
    }
    Timer {
        interval: 1500
        running: bars.anyWlrFullscreen
        repeat: true
        onTriggered: Hyprland.refreshToplevels()
    }
    Component.onCompleted: Hyprland.refreshToplevels()
}
