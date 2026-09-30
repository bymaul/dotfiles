pragma Singleton
import QtQuick
import Quickshell

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
}
