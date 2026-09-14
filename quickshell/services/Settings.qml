pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shell-owned settings: persisted to JSON, applied live.
// Hyprland look/feel applies at runtime via `hyprctl eval` (the Lua config
// rejects `hyprctl keyword`: "can't work with non-legacy parsers").
// hyprland.lua keeps the defaults; this store is an overlay re-applied on
// startup. Idle timeouts regenerate hypridle.conf + restart hypridle.
Singleton {
    id: settings

    // Appearance (shell-owned, applied by binding)
    property string wallpaperOverride: ""
    property var wallpapers: []

    // Hyprland look (hyprctl eval keywords)
    property bool blurEnabled: true
    property bool transparentFx: true
    property bool animEnabled: true

    // Hyprland input
    property real sensitivity: 0
    property real touchScroll: 0.8
    property bool naturalScroll: true

    // Idle timeouts in seconds (0 = that step disabled)
    property int dimTimeout: 150
    property int lockTimeout: 300
    property int screenOffTimeout: 330
    property int suspendTimeout: 1800

    property bool loaded: false
    // Last result-checked apply (shown in the Monitors page + via IPC).
    property string lastApplyMsg: ""
    property var applyQueue: []

    readonly property string settingsFile: {
        const xdg = Quickshell.env("XDG_DATA_HOME") ?? "";
        const base = xdg !== "" ? xdg : (Quickshell.env("HOME") ?? "") + "/.local/share";
        return base + "/quickshell/settings.json";
    }
    readonly property string hypridleFile: (Quickshell.env("HOME") ?? "") + "/.config/hypr/hypridle.conf"

    function num(v, d, lo, hi): real {
        if (typeof v !== "number" || isNaN(v))
            return d;
        return Math.max(lo, Math.min(hi, v));
    }
    function pickBool(v, d): bool {
        return typeof v === "boolean" ? v : d;
    }
    function pickStr(v, d): string {
        return typeof v === "string" ? v : d;
    }

    function snapshot(): var {
        return {
            wallpaperOverride: settings.wallpaperOverride,
            blurEnabled: settings.blurEnabled,
            transparentFx: settings.transparentFx,
            animEnabled: settings.animEnabled,
            sensitivity: settings.sensitivity,
            touchScroll: settings.touchScroll,
            naturalScroll: settings.naturalScroll,
            dimTimeout: settings.dimTimeout,
            lockTimeout: settings.lockTimeout,
            screenOffTimeout: settings.screenOffTimeout,
            suspendTimeout: settings.suspendTimeout,
            monitorConfigs: settings.monitorConfigs
        };
    }

    function applyLoaded(obj): void {
        if (!obj || typeof obj !== "object")
            return;
        settings.wallpaperOverride = settings.pickStr(obj.wallpaperOverride, "");
        settings.blurEnabled = settings.pickBool(obj.blurEnabled, true);
        settings.transparentFx = settings.pickBool(obj.transparentFx, true);
        settings.animEnabled = settings.pickBool(obj.animEnabled, true);
        settings.sensitivity = settings.num(obj.sensitivity, 0, -1, 1);
        settings.touchScroll = settings.num(obj.touchScroll, 0.8, 0.1, 2);
        settings.naturalScroll = settings.pickBool(obj.naturalScroll, true);
        settings.dimTimeout = Math.round(settings.num(obj.dimTimeout, 150, 0, 600));
        settings.lockTimeout = Math.round(settings.num(obj.lockTimeout, 300, 0, 3600));
        settings.screenOffTimeout = Math.round(settings.num(obj.screenOffTimeout, 330, 0, 3600));
        settings.suspendTimeout = Math.round(settings.num(obj.suspendTimeout, 1800, 0, 7200));
        if (obj.monitorConfigs && typeof obj.monitorConfigs === "object") {
            const clean = {};
            for (const name of Object.keys(obj.monitorConfigs)) {
                const e = obj.monitorConfigs[name];
                if (e && typeof e === "object")
                    clean[name] = e;
            }
            settings.monitorConfigs = clean;
        }
    }

    function hypr(key: string, value: string): void {
        Quickshell.execDetached(["hyprctl", "eval", settings.luaFor(key, value)]);
    }
    // "general:gaps_in" + "5" -> hl.config({general = {gaps_in = 5}})
    // "input:touchpad:natural_scroll" + "false" -> hl.config({input = {...}})
    function luaVal(v: string): string {
        if (v === "true" || v === "false")
            return v;
        if (v !== "" && !isNaN(Number(v)))
            return v;
        return '"' + v.replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
    }
    function luaFor(key: string, value: string): string {
        const parts = key.split(":");
        let inner = settings.luaVal(value);
        for (let i = parts.length - 1; i >= 0; i--) {
            if (i === parts.length - 1)
                inner = parts[i] + " = " + inner;
            else
                inner = parts[i] + " = {" + inner + "}";
        }
        return "hl.config({" + inner + "})";
    }

    // Push the full overlay to a live compositor (called after load).
    function applyAll(): void {
        settings.hypr("decoration:blur:enabled", settings.blurEnabled ? "true" : "false");
        settings.applyTransparency();
        settings.hypr("animations:enabled", settings.animEnabled ? "true" : "false");
        settings.hypr("input:sensitivity", String(settings.sensitivity));
        settings.hypr("input:touchpad:scroll_factor", String(settings.touchScroll));
        settings.hypr("input:touchpad:natural_scroll", settings.naturalScroll ? "true" : "false");
        Wallpaper.applyOverride(settings.wallpaperOverride);
    }
    // First monitor scan completion AND settings load (whichever comes
    // last): mark ready, then push stored configs once. Later scans only
    // refresh the list; user actions apply live.
    function applyScannedMonitors(): void {
        if (!settings.monitorsReady || !settings.loaded || settings.monitorsApplied)
            return;
        settings.monitorsApplied = true;
        for (const name of Object.keys(settings.monitorConfigs))
            settings.applyMonitor(name, true);
    }

    // Appearance
    function setWallpaper(path: string): void {
        settings.wallpaperOverride = path;
        Wallpaper.applyOverride(path);
        settings.scheduleSave();
    }
    function refreshWallpapers(): void {
        wallpaperScan.running = true;
    }

    // Hyprland setters: update, apply live, persist
    function setBlurEnabled(on: bool): void {
        settings.blurEnabled = on;
        settings.hypr("decoration:blur:enabled", on ? "true" : "false");
        settings.scheduleSave();
    }
    function applyTransparency(): void {
        if (settings.transparentFx)
            Quickshell.execDetached(["hyprctl", "eval", "hl.config({decoration = {active_opacity = 0.9, inactive_opacity = 0.87}})"]);
        else
            Quickshell.execDetached(["hyprctl", "eval", "hl.config({decoration = {active_opacity = 1.0, inactive_opacity = 1.0}})"]);
    }
    function setTransparentFx(on: bool): void {
        settings.transparentFx = on;
        settings.applyTransparency();
        settings.scheduleSave();
    }
    function setAnimEnabled(on: bool): void {
        settings.animEnabled = on;
        settings.hypr("animations:enabled", on ? "true" : "false");
        settings.scheduleSave();
    }
    function setSensitivity(v: real): void {
        settings.sensitivity = Math.round(Math.max(-1, Math.min(1, v)) * 10) / 10;
        settings.hypr("input:sensitivity", String(settings.sensitivity));
        settings.scheduleSave();
    }
    function setTouchScroll(v: real): void {
        settings.touchScroll = Math.round(Math.max(0.1, Math.min(2, v)) * 10) / 10;
        settings.hypr("input:touchpad:scroll_factor", String(settings.touchScroll));
        settings.scheduleSave();
    }
    function setNaturalScroll(on: bool): void {
        settings.naturalScroll = on;
        settings.hypr("input:touchpad:natural_scroll", on ? "true" : "false");
        settings.scheduleSave();
    }

    // Monitors: enumerate via hyprctl, apply via `hyprctl keyword monitor`
    function refreshMonitors(): void {
        monitorScan.running = true;
    }
    function monitorCfg(name: string): var {
        return settings.monitorConfigs[name] ?? {};
    }
    function monitorBase(name: string): int {
        const i = settings.monitors.findIndex(m => m && m.name === name);
        return i < 0 ? -1 : i * 3;
    }
    function monitorLive(name: string): var {
        return settings.monitors.find(m => m && m.name === name) ?? null;
    }
    function monitorEnabled(name: string): bool {
        const cfg = settings.monitorCfg(name);
        if (typeof cfg.enabled === "boolean")
            return cfg.enabled;
        const live = settings.monitorLive(name);
        return live ? live.disabled !== true : true;
    }
    // The last enabled display must stay on - disabling it leaves the
    // session with no output (and the stale config would re-disable it
    // on every startup). Empty list = unknown, don't block.
    function enabledMonitors(): var {
        return settings.monitors.filter(m => m && settings.monitorEnabled(m.name));
    }
    function canDisableMonitor(name: string): bool {
        // List not scanned yet (e.g. right after login): can't judge, allow.
        // Startup applies run after the first scan, so they stay correct.
        if (!settings.monitorsReady)
            return true;
        const enabled = settings.enabledMonitors();
        if (enabled.length === 0)
            return true;
        if (enabled.length > 1)
            return true;
        return enabled[0].name !== name;
    }
    function monitorScale(name: string): real {
        const cfg = settings.monitorCfg(name);
        if (typeof cfg.scale === "number" && !isNaN(cfg.scale))
            return Math.max(0.5, Math.min(3, cfg.scale));
        const live = settings.monitorLive(name);
        return live && typeof live.scale === "number" ? live.scale : 1;
    }
    function monitorModes(name: string): var {
        const modes = ["preferred"];
        const live = settings.monitorLive(name);
        if (live && Array.isArray(live.availableModes)) {
            for (const m of live.availableModes) {
                if (typeof m === "string" && m !== "" && !modes.includes(m))
                    modes.push(m);
            }
        }
        return modes;
    }
    function monitorRes(name: string): string {
        const cfg = settings.monitorCfg(name);
        if (typeof cfg.res === "string" && cfg.res !== "")
            return cfg.res;
        const live = settings.monitorLive(name);
        if (live && typeof live.width === "number" && typeof live.height === "number")
            return live.width + "x" + live.height + "@" + live.refreshRate + "Hz";
        return "preferred";
    }
    function monitorSummary(name: string): string {
        const live = settings.monitorLive(name);
        if (!live)
            return name;
        let s = name + "  " + live.width + "x" + live.height + "@" + live.refreshRate + "  x" + settings.monitorScale(name);
        if (live.disabled === true)
            s += "  (disabled)";
        return s;
    }
    function applyMonitor(name: string, quiet: bool): void {
        const q = !!quiet;
        if (!settings.monitorEnabled(name)) {
            if (!settings.canDisableMonitor(name)) {
                // Heal persisted state: never boot with zero displays.
                settings.putMonitorCfg(name, {enabled: true});
                settings.lastApplyMsg = name + " kept enabled (only display)";
                settings.scheduleSave();
                return;
            }
            settings.applyTracked(name + " disabled", 'hl.monitor({output = "' + name + '", disabled = true})', q);
            return;
        }
        const scale = String(settings.monitorScale(name));
        const desc = name + " -> " + settings.monitorRes(name) + " x" + scale;
        settings.applyTracked(desc, 'hl.monitor({output = "' + name + '", mode = "' + settings.monitorRes(name) + '", position = "auto", scale = "' + scale + '"})', q);
    }
    // Result-checked hyprctl eval with user feedback. Plain hypr() stays
    // for look/input; monitor changes go through here. hyprctl exits 0
    // even when it refuses work, so eval error text also counts as failure.
    // Jobs run serially; toasts share one syncId so slider drags replace
    // instead of flooding.
    function applyTracked(label: string, code: string, quiet: bool): void {
        settings.applyQueue = [...settings.applyQueue, {label: label, code: code, quiet: !!quiet}];
        settings.pumpApply();
    }
    function pumpApply(): void {
        if (monApply.running || settings.applyQueue.length === 0)
            return;
        const job = settings.applyQueue[0];
        settings.applyQueue = settings.applyQueue.slice(1);
        monApply.jobLabel = job.label;
        monApply.jobQuiet = job.quiet;
        monApply.command = ["hyprctl", "eval", job.code];
        monApply.running = true;
    }
    function putMonitorCfg(name: string, patch: var): void {
        const cfgs = Object.assign({}, settings.monitorConfigs);
        cfgs[name] = Object.assign({}, settings.monitorCfg(name), patch);
        settings.monitorConfigs = cfgs;
    }
    function setMonitorScale(name: string, v: real): void {
        settings.putMonitorCfg(name, {scale: Math.round(Math.max(0.5, Math.min(3, v)) * 20) / 20});
        settings.applyMonitor(name);
        settings.scheduleSave();
    }
    function setMonitorEnabled(name: string, on: bool): void {
        if (!on && !settings.canDisableMonitor(name)) {
            settings.lastApplyMsg = "Cannot disable " + name + " (only display)";
            Notifs.notify({app: "settings", summary: settings.lastApplyMsg, syncId: "settings-apply", timeout: 3000});
            return;
        }
        settings.putMonitorCfg(name, {enabled: on});
        settings.applyMonitor(name);
        settings.scheduleSave();
    }
    function cycleMonitorRes(name: string, dir: int): void {
        const modes = settings.monitorModes(name);
        let idx = modes.indexOf(settings.monitorRes(name));
        if (idx < 0)
            idx = 0;
        idx = (idx + dir + modes.length) % modes.length;
        settings.putMonitorCfg(name, {res: modes[idx]});
        settings.applyMonitor(name);
        settings.scheduleSave();
    }

    // Monitors, keyed by connector name (e.g. "eDP-1").
    // Live list comes from `hyprctl monitors -j`; configs overlay it.
    property var monitors: []
    property var monitorConfigs: ({})
    property bool monitorsReady: false
    property bool monitorsApplied: false

    // System (idle): update, rewrite hypridle.conf, restart daemon, persist
    function setDimTimeout(v: real): void {
        settings.dimTimeout = Math.round(Math.max(0, Math.min(600, v)));
        settings.writeIdleConf();
        settings.scheduleSave();
    }
    function setLockTimeout(v: real): void {
        settings.lockTimeout = Math.round(Math.max(0, Math.min(3600, v)));
        settings.writeIdleConf();
        settings.scheduleSave();
    }
    function setScreenOffTimeout(v: real): void {
        settings.screenOffTimeout = Math.round(Math.max(0, Math.min(3600, v)));
        settings.writeIdleConf();
        settings.scheduleSave();
    }
    function setSuspendTimeout(v: real): void {
        settings.suspendTimeout = Math.round(Math.max(0, Math.min(7200, v)));
        settings.writeIdleConf();
        settings.scheduleSave();
    }
    function writeIdleConf(): void {
        const L = [];
        L.push("general {");
        L.push("    lock_cmd = qs ipc call bar lock");
        L.push("    before_sleep_cmd = loginctl lock-session");
        L.push("    after_sleep_cmd = hyprctl dispatch dpms on");
        L.push("}");
        L.push("");
        if (settings.dimTimeout > 0) {
            L.push("listener {");
            L.push("    timeout = " + settings.dimTimeout);
            L.push("    on-timeout = brightnessctl -s set 10");
            L.push("    on-resume = brightnessctl -r");
            L.push("}");
            L.push("");
            L.push("listener {");
            L.push("    timeout = " + settings.dimTimeout);
            L.push("    on-timeout = brightnessctl -sd rgb:kbd_backlight set 0");
            L.push("    on-resume = brightnessctl -rd rgb:kbd_backlight");
            L.push("}");
            L.push("");
        }
        if (settings.lockTimeout > 0) {
            L.push("listener {");
            L.push("    timeout = " + settings.lockTimeout);
            L.push("    on-timeout = loginctl lock-session");
            L.push("}");
            L.push("");
        }
        if (settings.screenOffTimeout > 0) {
            L.push("listener {");
            L.push("    timeout = " + settings.screenOffTimeout);
            L.push("    on-timeout = hyprctl dispatch dpms off");
            L.push("    on-resume = hyprctl dispatch dpms on");
            L.push("}");
            L.push("");
        }
        if (settings.suspendTimeout > 0) {
            L.push("listener {");
            L.push("    timeout = " + settings.suspendTimeout);
            L.push("    on-timeout = systemctl suspend");
            L.push("}");
            L.push("");
        }
        idleWriter.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")"; printf "%s\\n" "$2" > "$1"', "qs", settings.hypridleFile, L.join("\n")];
        idleWriter.running = true;
    }

    // Persistence (same mkdir+printf pattern as LaunchHistory)
    property bool saveQueued: false
    function scheduleSave(): void {
        if (!settings.loaded)
            return;
        settings.saveQueued = true;
        saveTimer.restart();
    }
    Timer {
        id: saveTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (!settings.saveQueued)
                return;
            settings.saveQueued = false;
            saver.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s\\n" "$1" > "$2"', "qs", JSON.stringify(settings.snapshot()), settings.settingsFile];
            saver.running = true;
        }
    }
    Process {
        id: saver
        onExited: exitCode => {
            if (exitCode !== 0 && settings.saveQueued)
                saveTimer.restart();
        }
    }
    Process {
        id: loader
        command: ["cat", settings.settingsFile]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    settings.applyLoaded(JSON.parse(text));
                } catch (_) {}
                settings.loaded = true;
                if (text.trim() !== "")
                    settings.applyAll();
                settings.applyScannedMonitors();
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                settings.loaded = true;
            }
        }
        Component.onCompleted: loader.running = true
    }
    Process {
        id: wallpaperScan
        command: ["sh", "-c", "for d in \"$HOME/dotfiles/wallpapers\" \"$HOME/Pictures/Wallpapers\"; do [ -d \"$d\" ] && find \"$d\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null; done | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                settings.wallpapers = text.trim().split("\n").filter(s => s !== "");
            }
        }
    }
    Process {
        id: monitorScan
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text);
                    settings.monitors = Array.isArray(arr) ? arr : [];
                } catch (_) {
                    settings.monitors = [];
                }
                settings.monitorsReady = true;
                settings.applyScannedMonitors();
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                settings.monitors = [];
                settings.monitorsReady = true;
                settings.applyScannedMonitors();
            }
        }
        Component.onCompleted: monitorScan.running = true
    }
    Process {
        id: monApply
        property string jobLabel: ""
        property bool jobQuiet: false
        stdout: StdioCollector {
            id: monOut
        }
        stderr: StdioCollector {
            id: monErr
        }
        onExited: exitCode => {
            const detail = (monErr.text + " " + monOut.text).trim();
            const failed = exitCode !== 0 || /error/i.test(detail);
            if (!failed) {
                settings.lastApplyMsg = monApply.jobLabel + " applied";
                if (!monApply.jobQuiet)
                    Notifs.notify({app: "settings", summary: settings.lastApplyMsg, syncId: "settings-apply", timeout: 1500});
            } else {
                settings.lastApplyMsg = "Failed: " + monApply.jobLabel + (detail !== "" ? " (" + detail.slice(0, 120) + ")" : "");
                Notifs.notify({app: "settings", summary: "Setting failed", body: settings.lastApplyMsg, syncId: "settings-apply", timeout: 5000});
            }
            settings.pumpApply();
        }
    }
    Process {
        id: idleWriter
        onExited: exitCode => {
            if (exitCode === 0)
                Quickshell.execDetached(["sh", "-c", "pkill -x hypridle 2>/dev/null; sleep 0.2; hypridle >/dev/null 2>&1 &"]);
        }
    }
}
