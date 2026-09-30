function num(v, d, lo, hi) {
    if (typeof v !== "number" || isNaN(v))
        return d;
    return Math.max(lo, Math.min(hi, v));
}

function pickBool(v, d) {
    return typeof v === "boolean" ? v : d;
}

function pickStr(v, d) {
    return typeof v === "string" ? v : d;
}

function pickOpt(v, d, opts) {
    return typeof v === "string" && opts.includes(v) ? v : d;
}

function liveModeStr(live) {
    if (!live || typeof live.width !== "number" || typeof live.height !== "number")
        return "";
    if (typeof live.refreshRate === "number")
        return live.width + "x" + live.height + "@" + live.refreshRate.toFixed(2) + "Hz";
    return live.width + "x" + live.height;
}

function monitorPosOptions() {
    return ["auto", "auto-right", "auto-left", "auto-up", "auto-down"];
}

function cycleOpt(list, cur, dir) {
    let i = list.indexOf(cur);
    if (i < 0)
        i = 0;
    return list[(i + dir + list.length) % list.length];
}

function fmtTimeout(s) {
    if (s <= 0)
        return "Off";
    if (s < 60)
        return s + "s";
    if (s < 3600) {
        const m = Math.floor(s / 60);
        const rest = s % 60;
        return rest === 0 ? m + "m" : m + "m " + rest + "s";
    }
    const h = Math.floor(s / 3600);
    const rest = Math.floor((s % 3600) / 60);
    return rest === 0 ? h + "h" : h + "h " + rest + "m";
}
