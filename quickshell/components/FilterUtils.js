function fuzzyMatch(t, query) {
    let qi = 0;
    for (let ti = 0; ti < t.length && qi < query.length; ti++) {
        if (t[ti] === query[qi])
            qi++;
    }
    return qi >= query.length;
}

function matchScoreLn(t, query) {
    if (query === "")
        return 1;
    if (t === query)
        return 0;
    if (t.startsWith(query))
        return 1;
    if (t.includes(query))
        return 2;
    if (fuzzyMatch(t, query))
        return 3;
    return 4;
}

function matchScore(text, q) {
    return matchScoreLn(String(text ?? "").toLowerCase(), String(q ?? "").toLowerCase());
}

function escHtml(s) {
    return String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function hlFuzzy(raw, query) {
    const src = String(raw ?? "");
    const lower = src.toLowerCase();
    const q = String(query ?? "");
    let qi = 0;
    let out = "";
    for (let ti = 0; ti < src.length; ti++) {
        const ch = src[ti];
        const c = ch === "&" ? "&amp;" : ch === "<" ? "&lt;" : ch === ">" ? "&gt;" : ch === '"' ? "&quot;" : ch;
        if (qi < q.length && lower[ti] === q[qi]) {
            out += "<u>" + c + "</u>";
            qi++;
        } else {
            out += c;
        }
    }
    return out;
}

function hlName(name, q) {
    const raw = String(name ?? "");
    const query = String(q ?? "");
    if (query === "")
        return escHtml(raw);
    const low = raw.toLowerCase();
    const i = low.indexOf(query);
    if (i >= 0)
        return escHtml(raw.slice(0, i)) + "<u>" + escHtml(raw.slice(i, i + query.length)) + "</u>" + escHtml(raw.slice(i + query.length));
    return hlFuzzy(raw, query);
}
