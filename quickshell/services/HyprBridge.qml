pragma Singleton
import QtQuick
import Quickshell

// Debounced writer for `hyprctl eval hl.config(...)` calls.
// Pure: no dependency on Settings or any other singleton.
Singleton {
    id: bridge

    property var pending: ({})

    function hypr(key: string, value: string): void {
        bridge.queue(key, value);
    }
    function queue(key: string, value: string): void {
        const next = Object.assign({}, bridge.pending);
        next[key] = value;
        bridge.pending = next;
        debounce.restart();
    }
    function now(key: string, value: string): void {
        bridge.eval(bridge.luaFor(key, value));
    }
    function eval(code: string): void {
        Quickshell.execDetached(["hyprctl", "eval", code]);
    }
    Timer {
        id: debounce
        interval: 150
        repeat: false
        onTriggered: {
            const due = bridge.pending;
            bridge.pending = {};
            for (const key of Object.keys(due))
                bridge.now(key, due[key]);
        }
    }
    function luaVal(v: string): string {
        if (v === "true" || v === "false")
            return v;
        if (v !== "" && !isNaN(Number(v)))
            return v;
        return bridge.luaStr(v);
    }
    function luaStr(v: string): string {
        return '"' + String(v ?? "").replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, " ") + '"';
    }
    function luaFor(key: string, value: string): string {
        const parts = key.split(":");
        let inner = bridge.luaVal(value);
        for (let i = parts.length - 1; i >= 0; i--) {
            if (i === parts.length - 1)
                inner = parts[i] + " = " + inner;
            else
                inner = parts[i] + " = {" + inner + "}";
        }
        return "hl.config({" + inner + "})";
    }
}
