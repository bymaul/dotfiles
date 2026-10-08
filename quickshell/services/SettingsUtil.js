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

function posLabels() {
    return {
        "auto": "Auto",
        "auto-right": "Auto · right",
        "auto-left": "Auto · left",
        "auto-up": "Auto · above",
        "auto-down": "Auto · below"
    };
}

function posLabel(raw) {
    const m = posLabels();
    if (m[raw] !== undefined)
        return m[raw];
    const p = parsePos(raw);
    if (p !== null)
        return "(" + p.x + ", " + p.y + ")";
    return String(raw ?? "");
}

function parsePos(s) {
    if (typeof s !== "string" || s === "")
        return null;
    const m = s.match(/^([+-]?\d+)x([+-]?\d+)$/);
    if (!m)
        return null;
    return {x: parseInt(m[1], 10), y: parseInt(m[2], 10)};
}

function isExplicitPos(s) {
    return parsePos(s) !== null;
}

function isValidMonitorPos(s) {
    return monitorPosOptions().includes(s) || isExplicitPos(s);
}

function fmtPos(x, y) {
    return Math.round(x) + "x" + Math.round(y);
}

function parseMode(s) {
    if (typeof s !== "string" || s === "")
        return {valid: false, w: 0, h: 0, rate: 0, resKey: "", rateLabel: ""};
    if (s === "preferred")
        return {valid: true, preferred: true, w: 0, h: 0, rate: 0, resKey: "Preferred", rateLabel: "Preferred"};
    const m = s.match(/^(\d+)x(\d+)(?:@([\d.]+)Hz)?$/);
    if (!m)
        return {valid: false, w: 0, h: 0, rate: 0, resKey: "", rateLabel: ""};
    const w = parseInt(m[1], 10);
    const h = parseInt(m[2], 10);
    const rate = m[3] !== undefined ? parseFloat(m[3]) : 0;
    const resKey = w + "x" + h;
    const rateLabel = m[3] !== undefined ? Number(rate).toFixed(2) + "Hz" : "";
    return {valid: true, w: w, h: h, rate: isNaN(rate) ? 0 : rate, resKey: resKey, rateLabel: rateLabel};
}

function resKeyOf(mode) {
    if (mode === "preferred")
        return "Preferred";
    const p = parseMode(mode);
    return p.valid ? p.resKey : String(mode ?? "");
}

function dedupeSortModes(modes) {
    const list = Array.isArray(modes) ? modes : [];
    const hasPreferred = list.includes("preferred");
    const seen = {};
    const rest = [];
    for (const m of list) {
        if (typeof m !== "string" || m === "" || m === "preferred")
            continue;
        if (seen[m])
            continue;
        seen[m] = true;
        const p = parseMode(m);
        if (!p.valid)
            continue;
        rest.push(m);
    }
    rest.sort((a, b) => {
        const pa = parseMode(a);
        const pb = parseMode(b);
        const aa = pa.w * pa.h;
        const ab = pb.w * pb.h;
        if (ab !== aa)
            return ab - aa;
        return pb.rate - pa.rate;
    });
    return hasPreferred ? ["preferred"].concat(rest) : rest;
}

function resolutionsFor(modes) {
    const list = Array.isArray(modes) ? modes : [];
    const seen = {};
    const out = [];
    for (const m of list) {
        if (m === "preferred")
            continue;
        const p = parseMode(m);
        if (!p.valid)
            continue;
        if (seen[p.resKey])
            continue;
        seen[p.resKey] = {w: p.w, h: p.h};
        out.push(p.resKey);
    }
    out.sort((a, b) => {
        const pa = seen[a];
        const pb = seen[b];
        return (pb.w * pb.h) - (pa.w * pa.h);
    });
    return out;
}

function ratesForMode(modes, resKey) {
    const list = Array.isArray(modes) ? modes : [];
    const out = [];
    for (const m of list) {
        if (m === "preferred")
            continue;
        const p = parseMode(m);
        if (!p.valid || p.resKey !== resKey)
            continue;
        if (!out.includes(m))
            out.push(m);
    }
    out.sort((a, b) => parseMode(b).rate - parseMode(a).rate);
    return out;
}

function diagInches(live) {
    if (!live || !(live.physicalWidth > 0) || !(live.physicalHeight > 0))
        return 0;
    return Math.sqrt(live.physicalWidth * live.physicalWidth + live.physicalHeight * live.physicalHeight) / 25.4;
}

function monitorDetails(live) {
    if (!live)
        return "";
    const diag = diagInches(live);
    const parts = [];
    if (diag > 0) {
        parts.push(diag.toFixed(1) + '"');
        if (typeof live.width === "number" && typeof live.height === "number") {
            const diagPx = Math.sqrt(live.width * live.width + live.height * live.height);
            parts.push(Math.round(diagPx / diag) + " DPI");
        }
    }
    return parts.join("  ·  ");
}

function validScaleValues(w, h) {
    const W = Number(w), H = Number(h);
    if (!(W > 0) || !(H > 0))
        return [1];
    const out = [];
    for (let k = 10; k <= 60; k++) {
        const s = k / 20;
        if (Math.abs(W / s - Math.round(W / s)) < 0.001 && Math.abs(H / s - Math.round(H / s)) < 0.001)
            out.push(s);
    }
    if (out.length === 0)
        return [1];
    return out;
}

function nearestValidScale(w, h, v) {
    const opts = validScaleValues(w, h);
    let best = opts[0], bd = Math.abs(opts[0] - v);
    for (const o of opts) {
        const d = Math.abs(o - v);
        if (d < bd - 1e-9) {
            bd = d;
            best = o;
        }
    }
    return best;
}

function nextValidScale(w, h, cur, dir) {
    const opts = validScaleValues(w, h);
    if (dir > 0) {
        for (const o of opts) {
            if (o > cur + 0.001)
                return o;
        }
        return opts[opts.length - 1];
    }
    for (let i = opts.length - 1; i >= 0; i--) {
        if (opts[i] < cur - 0.001)
            return opts[i];
    }
    return opts[0];
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
