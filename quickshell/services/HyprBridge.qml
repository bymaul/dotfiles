pragma Singleton
import QtQuick
import Quickshell

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
        bridge.evalCode(bridge.luaFor(key, value));
    }
    function evalCode(code: string): void {
        if (typeof code !== "string" || code === "" || code.length > 2048)
            return;
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
        const s = String(v ?? "").slice(0, 256).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\r/g, " ").replace(/\n/g, " ").replace(/[\x00-\x1F\x7F]/g, " ");
        return '"' + s + '"';
    }
    function luaFor(key: string, value: string): string {
        if (!key || typeof key !== "string" || key.length > 128)
            return "";
        if (!/^[A-Za-z0-9_:.-]+$/.test(key))
            return "";
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
