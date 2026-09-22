pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: settings

    property string wallpaperOverride: ""
    property var wallpapers: []

    property bool blurEnabled: true
    property bool transparentFx: true
    property bool animEnabled: true

    property real sensitivity: 0
    property real touchScroll: 0.8
    property bool naturalScroll: true

    property int dimTimeout: 150
    property int lockTimeout: 300
    property int screenOffTimeout: 330
    property int suspendTimeout: 1800

    property int lowBatteryPct: 20
    property int criticalBatteryPct: 10
    property string criticalBatteryAction: "suspend"
    property string lidCloseAction: "suspend"
    property string powerButtonAction: "menu"
    property string powerProfileOnBattery: "keep"

    property bool loaded: false
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
    function pickOpt(v, d, opts): string {
        return typeof v === "string" && opts.includes(v) ? v : d;
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
            lowBatteryPct: settings.lowBatteryPct,
            criticalBatteryPct: settings.criticalBatteryPct,
            criticalBatteryAction: settings.criticalBatteryAction,
            lidCloseAction: settings.lidCloseAction,
            powerButtonAction: settings.powerButtonAction,
            powerProfileOnBattery: settings.powerProfileOnBattery,
            mainMonitor: settings.mainMonitor,
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
        settings.lowBatteryPct = Math.round(settings.num(obj.lowBatteryPct, 20, 5, 50));
        settings.criticalBatteryPct = Math.min(Math.round(settings.num(obj.criticalBatteryPct, 10, 3, 30)), settings.lowBatteryPct);
        settings.criticalBatteryAction = settings.pickOpt(obj.criticalBatteryAction, "suspend", ["suspend", "hibernate", "poweroff", "lock", "notify"]);
        settings.lidCloseAction = settings.pickOpt(obj.lidCloseAction, "suspend", ["suspend", "lock", "ignore"]);
        settings.powerButtonAction = settings.pickOpt(obj.powerButtonAction, "menu", ["menu", "suspend", "lock", "poweroff", "ignore"]);
        settings.powerProfileOnBattery = settings.pickOpt(obj.powerProfileOnBattery, "keep", ["keep", "powersaver", "balanced", "performance"]);
        settings.mainMonitor = settings.pickStr(obj.mainMonitor, "auto");
        if (obj.monitorConfigs && typeof obj.monitorConfigs === "object") {
            const clean = {};
            for (const name of Object.keys(obj.monitorConfigs)) {
                if (typeof name !== "string" || name === "")
                    continue;
                const e = obj.monitorConfigs[name];
                if (!e || typeof e !== "object")
                    continue;
                const entry = {};
                if (typeof e.enabled === "boolean")
                    entry.enabled = e.enabled;
                if (typeof e.scale === "number" && !isNaN(e.scale))
                    entry.scale = Math.max(0.5, Math.min(3, e.scale));
                if (typeof e.res === "string" && e.res !== "")
                    entry.res = e.res.slice(0, 64);
                if (typeof e.pos === "string" && ["auto", "auto-right", "auto-left", "auto-up", "auto-down"].includes(e.pos))
                    entry.pos = e.pos;
                clean[name] = entry;
            }
            settings.monitorConfigs = clean;
        }
    }

    function applyAll(): void {
        HyprBridge.hypr("decoration:blur:enabled", settings.blurEnabled ? "true" : "false");
        settings.applyTransparency();
        HyprBridge.hypr("animations:enabled", settings.animEnabled ? "true" : "false");
        HyprBridge.hypr("input:sensitivity", String(settings.sensitivity));
        HyprBridge.hypr("input:touchpad:scroll_factor", String(settings.touchScroll));
        HyprBridge.hypr("input:touchpad:natural_scroll", settings.naturalScroll ? "true" : "false");
        Wallpaper.applyOverride(settings.wallpaperOverride);
    }
    function applyScannedMonitors(): void {
        if (!settings.monitorsReady || !settings.loaded)
            return;
        for (const name of Object.keys(settings.monitorConfigs)) {
            if (settings.appliedMonitors.includes(name))
                continue;
            if (!settings.monitorLive(name))
                continue;
            settings.appliedMonitors = [...settings.appliedMonitors, name];
            settings.applyMonitor(name, true);
        }
    }

    function setWallpaper(path: string): void {
        settings.wallpaperOverride = path;
        Wallpaper.applyOverride(path);
        settings.scheduleSave();
    }
    function refreshWallpapers(): void {
        if (!wallpaperScan.running)
            wallpaperScan.running = true;
    }

    function setBlurEnabled(on: bool): void {
        settings.blurEnabled = on;
        HyprBridge.hypr("decoration:blur:enabled", on ? "true" : "false");
        settings.scheduleSave();
    }
    function applyTransparency(): void {
        if (settings.transparentFx)
            HyprBridge.evalCode("hl.config({decoration = {active_opacity = 0.9, inactive_opacity = 0.87}})");
        else
            HyprBridge.evalCode("hl.config({decoration = {active_opacity = 1.0, inactive_opacity = 1.0}})");
    }
    function setTransparentFx(on: bool): void {
        settings.transparentFx = on;
        settings.applyTransparency();
        settings.scheduleSave();
    }
    function setAnimEnabled(on: bool): void {
        settings.animEnabled = on;
        HyprBridge.hypr("animations:enabled", on ? "true" : "false");
        settings.scheduleSave();
    }
    function setSensitivity(v: real): void {
        settings.sensitivity = Math.round(Math.max(-1, Math.min(1, v)) * 10) / 10;
        HyprBridge.hypr("input:sensitivity", String(settings.sensitivity));
        settings.scheduleSave();
    }
    function setTouchScroll(v: real): void {
        settings.touchScroll = Math.round(Math.max(0.1, Math.min(2, v)) * 10) / 10;
        HyprBridge.hypr("input:touchpad:scroll_factor", String(settings.touchScroll));
        settings.scheduleSave();
    }
    function setNaturalScroll(on: bool): void {
        settings.naturalScroll = on;
        HyprBridge.hypr("input:touchpad:natural_scroll", on ? "true" : "false");
        settings.scheduleSave();
    }

    function refreshMonitors(): void {
        if (!monitorScan.running)
            monitorScan.running = true;
    }
    function monitorCfg(name: string): var {
        return settings.monitorConfigs[name] ?? {};
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
    function enabledMonitors(): var {
        return settings.monitors.filter(m => m && settings.monitorEnabled(m.name));
    }
    function canDisableMonitor(name: string): bool {
        if (!settings.monitorsReady)
            return false;
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
        if (live && typeof live.width === "number" && typeof live.height === "number") {
            if (typeof live.refreshRate === "number")
                return live.width + "x" + live.height + "@" + live.refreshRate.toFixed(2) + "Hz";
            return live.width + "x" + live.height;
        }
        return "preferred";
    }
    function monitorSummary(name: string): string {
        const live = settings.monitorLive(name);
        if (!live || typeof live.width !== "number" || typeof live.height !== "number")
            return name;
        const rate = typeof live.refreshRate === "number" ? live.refreshRate.toFixed(2) : "?";
        let s = name + "  " + live.width + "x" + live.height + "@" + rate + "  x" + settings.monitorScale(name);
        const pos = settings.monitorPos(name);
        if (pos !== "auto")
            s += "  " + pos;
        if (live.disabled === true)
            s += "  (disabled)";
        return s;
    }
    function applyMonitor(name: string, quiet: bool): void {
        const q = !!quiet;
        if (typeof name !== "string" || name === "")
            return;
        if (!q && !settings.appliedMonitors.includes(name))
            settings.appliedMonitors = [...settings.appliedMonitors, name];
        if (!settings.monitorEnabled(name)) {
            if (!settings.canDisableMonitor(name)) {
                settings.putMonitorCfg(name, {enabled: true});
                settings.lastApplyMsg = name + " kept enabled (only display)";
                settings.scheduleSave();
                return;
            }
            settings.applyTracked(name + " disabled", 'hl.monitor({output = ' + HyprBridge.luaStr(name) + ', disabled = true})', q, name);
            return;
        }
        const scale = String(settings.monitorScale(name));
        const res = String(settings.monitorRes(name));
        const pos = settings.monitorPos(name);
        const desc = name + " -> " + res + " x" + scale + (pos !== "auto" ? " " + pos : "");
        settings.applyTracked(desc, 'hl.monitor({output = ' + HyprBridge.luaStr(name) + ', disabled = false, mode = ' + HyprBridge.luaStr(res) + ', position = ' + HyprBridge.luaStr(pos) + ', scale = ' + HyprBridge.luaStr(scale) + '})', q, name);
    }
    function monitorPosOptions(): var {
        return ["auto", "auto-right", "auto-left", "auto-up", "auto-down"];
    }
    function monitorPos(name: string): string {
        const cfg = settings.monitorCfg(name);
        if (typeof cfg.pos === "string" && settings.monitorPosOptions().includes(cfg.pos))
            return cfg.pos;
        return "auto";
    }
    function applyTracked(label: string, code: string, quiet: bool, key: string): void {
        const k = typeof key === "string" && key !== "" ? key : label;
        settings.applyQueue = [...settings.applyQueue.filter(j => j.key !== k), {label: label, code: code, quiet: !!quiet, key: k}];
        if (settings.applyQueue.length > 20)
            settings.applyQueue = settings.applyQueue.slice(settings.applyQueue.length - 20);
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
        applyTimeout.restart();
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
    function setMonitorRes(name: string, res: string): void {
        settings.putMonitorCfg(name, {res: res});
        settings.applyMonitor(name);
        settings.scheduleSave();
    }
    function cycleMonitorRes(name: string, dir: int): void {
        const modes = settings.monitorModes(name);
        let idx = modes.indexOf(settings.monitorRes(name));
        if (idx < 0)
            idx = 0;
        idx = (idx + dir + modes.length) % modes.length;
        settings.setMonitorRes(name, modes[idx]);
    }
    function setMonitorPos(name: string, pos: string): void {
        if (!settings.monitorPosOptions().includes(pos))
            return;
        settings.putMonitorCfg(name, {pos: pos});
        settings.applyMonitor(name);
        settings.scheduleSave();
    }
    function cycleMonitorPos(name: string, dir: int): void {
        const opts = settings.monitorPosOptions();
        let idx = opts.indexOf(settings.monitorPos(name));
        if (idx < 0)
            idx = 0;
        idx = (idx + dir + opts.length) % opts.length;
        settings.setMonitorPos(name, opts[idx]);
    }

    property var monitors: []
    property var monitorConfigs: ({})
    property string mainMonitor: "auto"
    function setMainMonitor(name: string): void {
        settings.mainMonitor = (typeof name === "string" && name !== "") ? name : "auto";
        settings.scheduleSave();
    }
    property var barByScreen: ({})
    function registerBar(name: string, win: var): void {
        if (typeof name !== "string" || name === "" || !win)
            return;
        const next = Object.assign({}, settings.barByScreen);
        for (const k of Object.keys(next)) {
            if (next[k] === win && k !== name)
                delete next[k];
        }
        next[name] = win;
        settings.barByScreen = next;
    }
    function unregisterBar(win: var): void {
        if (!win)
            return;
        const next = Object.assign({}, settings.barByScreen);
        let changed = false;
        for (const k of Object.keys(next)) {
            if (next[k] === win) {
                delete next[k];
                changed = true;
            }
        }
        if (changed)
            settings.barByScreen = next;
    }
    function barForScreen(name: string): var {
        if (typeof name !== "string" || name === "")
            return null;
        return settings.barByScreen[name] ?? null;
    }
    function mainScreen(screens, focusedName): var {
        const list = screens ?? [];
        const want = settings.mainMonitor;
        if (typeof want === "string" && want !== "" && want !== "auto") {
            const hit = list.find(s => s && s.name === want);
            if (hit)
                return hit;
            if (typeof focusedName === "string" && focusedName !== "") {
                const fhit = list.find(s => s && s.name === focusedName);
                if (fhit)
                    return fhit;
            }
        }
        return list.length > 0 ? list[0] : null;
    }
    function popupScreen(screens, focusedName): var {
        const list = screens ?? [];
        if (typeof focusedName === "string" && focusedName !== "") {
            const fhit = list.find(s => s && s.name === focusedName);
            if (fhit)
                return fhit;
        }
        return settings.mainScreen(list, focusedName);
    }
    property bool monitorsReady: false
    property var appliedMonitors: []

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
    function setLowBatteryPct(v: real): void {
        settings.lowBatteryPct = Math.round(Math.max(5, Math.min(50, v)));
        if (settings.criticalBatteryPct > settings.lowBatteryPct)
            settings.criticalBatteryPct = settings.lowBatteryPct;
        settings.scheduleSave();
    }
    function setCriticalBatteryPct(v: real): void {
        settings.criticalBatteryPct = Math.min(Math.round(Math.max(3, Math.min(30, v))), settings.lowBatteryPct);
        settings.scheduleSave();
    }
    function setCriticalBatteryAction(v: string): void {
        if (!["suspend", "hibernate", "poweroff", "lock", "notify"].includes(v))
            return;
        settings.criticalBatteryAction = v;
        settings.scheduleSave();
    }
    function setLidCloseAction(v: string): void {
        if (!["suspend", "lock", "ignore"].includes(v))
            return;
        settings.lidCloseAction = v;
        settings.scheduleSave();
    }
    function setPowerButtonAction(v: string): void {
        if (!["menu", "suspend", "lock", "poweroff", "ignore"].includes(v))
            return;
        settings.powerButtonAction = v;
        settings.scheduleSave();
    }
    function setPowerProfileOnBattery(v: string): void {
        if (!["keep", "powersaver", "balanced", "performance"].includes(v))
            return;
        settings.powerProfileOnBattery = v;
        settings.scheduleSave();
    }
    function writeIdleConf(): void {
        IdleManager.request(settings.dimTimeout, settings.lockTimeout, settings.screenOffTimeout, settings.suspendTimeout, settings.hypridleFile);
    }

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
            if (saver.running)
                return;
            settings.saveQueued = false;
            saver.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s\\n" "$1" > "$2.tmp"; mv -f "$2.tmp" "$2"', "qs", JSON.stringify(settings.snapshot()), settings.settingsFile];
            saver.running = true;
        }
    }
    Process {
        id: saver
        onExited: exitCode => {
            if (exitCode !== 0) {
                settings.saveQueued = true;
                saveTimer.restart();
            } else if (settings.saveQueued) {
                saveTimer.restart();
            }
        }
    }
    Process {
        id: loader
        command: ["cat", settings.settingsFile]
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = null;
                let corrupt = false;
                try {
                    parsed = JSON.parse(text);
                } catch (_) {
                    corrupt = text.trim() !== "";
                }
                if (corrupt) {
                    console.warn("quickshell: settings.json corrupt, keeping defaults; backup at settings.json.corrupt-" + Date.now());
                    Quickshell.execDetached(["sh", "-c", 'cp "$1" "$1.corrupt-$(date +%s)" 2>/dev/null', "qs", settings.settingsFile]);
                    Notifs.notify({app: "settings", summary: "Settings file corrupt, defaults kept", body: "Backup saved next to settings.json", syncId: "settings-load", timeout: 8000});
                } else {
                    settings.applyLoaded(parsed);
                }
                settings.loaded = true;
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
        command: ["hyprctl", "monitors", "all", "-j"]
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
            applyTimeout.stop();
            const detail = (monErr.text + " " + monOut.text).trim();
            const failed = exitCode !== 0 || /error|failed|invalid|unknown|not found|no such/i.test(detail);
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
    Timer {
        id: applyTimeout
        interval: 10000
        repeat: false
        onTriggered: {
            if (monApply.running) {
                monApply.running = false;
                settings.lastApplyMsg = "Timed out: " + monApply.jobLabel;
                settings.pumpApply();
            }
        }
    }
}
