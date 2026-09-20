import QtQuick
import Quickshell
import "../components"
import "../services" as Services
BasePopup {
    id: root
    anchorMode: "middle"
    focusTarget: queryField
    implicitWidth: Services.Theme.launcherWidth
    implicitHeight: 16 + Services.Theme.rowHeight + Services.Theme.popupSpacing * 2 + Services.Theme.listHeight(Services.Theme.listVisible) + hint.implicitHeight
    function quitArmed(): bool {
        return !queryField.activeFocus;
    }
    Shortcut { sequence: "Down"; enabled: root.visible && !queryField.activeFocus; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Up"; enabled: root.visible && !queryField.activeFocus; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Return"; enabled: root.visible && !queryField.activeFocus; onActivated: root.launch() }
    Shortcut { sequence: "Enter"; enabled: root.visible && !queryField.activeFocus; onActivated: root.launch() }
    Shortcut { sequence: "Tab"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Ctrl+N"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Ctrl+P"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Ctrl+Y"; enabled: root.visible; onActivated: root.launch() }
    property var appsCache: null
    property var entries: []
    property bool selMoved: false
    readonly property bool runMode: String(queryField.text ?? "").trim().startsWith(">")
    readonly property string runQuery: String(queryField.text ?? "").trim().slice(1).trim().toLowerCase()
    onVisibleChanged: {
        if (visible) {
            root.appsCache = DesktopEntries.applications?.values ?? [];
            Services.RunMode.refresh();
            Services.LaunchHistory.load();
            queryField.text = "";
            root.selMoved = false;
            root.refilter();
        }
    }
    Connections {
        target: Services.RunMode
        function onBinariesChanged() {
            if (root.visible && root.runMode)
                root.refilter();
        }
    }
    function refreshApps(): void {
        if (root.visible && !root.runMode) {
            root.appsCache = DesktopEntries.applications?.values ?? [];
            root.refilter();
        }
    }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            refreshApps();
        }
        function onObjectInsertedPost() {
            refreshApps();
        }
    }
    Connections {
        target: Services.LaunchHistory
        function onLoadedChanged() {
            if (root.visible)
                root.refilter();
        }
    }
    function stepSelection(dir: int): void {
        root.flushRefilter();
        stepListView(resultList, dir);
        root.selMoved = true;
    }
    function flushRefilter(): void {
        if (refilterTimer.running) {
            refilterTimer.stop();
            root.refilter();
        }
    }
    Timer {
        id: refilterTimer
        interval: Services.Theme.refilterDelay
        repeat: false
        onTriggered: {
            if (root.visible)
                root.refilter();
        }
    }
    function refilter(): void {
        if (root.runMode)
            root.refilterRun(root.runQuery);
        else
            root.refilterApps(String(queryField.text ?? "").toLowerCase().trim());
    }
    function fuzzyMatch(t: string, query: string): bool {
        let qi = 0;
        for (let ti = 0; ti < t.length && qi < query.length; ti++) {
            if (t[ti] === query[qi])
                qi++;
        }
        return qi >= query.length;
    }
    function matchScoreLn(t: string, query: string): int {
        if (query === "")
            return 1;
        if (t === query)
            return 0;
        if (t.startsWith(query))
            return 1;
        if (t.includes(query))
            return 2;
        if (root.fuzzyMatch(t, query))
            return 3;
        return 4;
    }
    function matchScore(text: string, q: string): int {
        return root.matchScoreLn(String(text ?? "").toLowerCase(), String(q ?? "").toLowerCase());
    }
    function hlQuery(): string {
        return root.runMode ? root.runQuery : String(queryField.text ?? "").toLowerCase().trim();
    }
    function escHtml(s: string): string {
        return String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
    }
    function hlFuzzy(raw: string, query: string): string {
        const lower = raw.toLowerCase();
        let qi = 0;
        let out = "";
        for (let ti = 0; ti < raw.length; ti++) {
            const ch = raw[ti];
            const c = ch === "&" ? "&amp;" : ch === "<" ? "&lt;" : ch === ">" ? "&gt;" : ch === '"' ? "&quot;" : ch;
            if (qi < query.length && lower[ti] === query[qi]) {
                out += "<u>" + c + "</u>";
                qi++;
            } else {
                out += c;
            }
        }
        return out;
    }
    function hlName(name: string, q: string): string {
        const raw = String(name ?? "");
        const query = String(q ?? "");
        if (query === "")
            return root.escHtml(raw);
        const low = raw.toLowerCase();
        const i = low.indexOf(query);
        if (i >= 0) {
            const esc = root.escHtml;
            return esc(raw.slice(0, i)) + "<u>" + esc(raw.slice(i, i + query.length)) + "</u>" + esc(raw.slice(i + query.length));
        }
        return root.hlFuzzy(raw, query);
    }
    function entryKey(e): string {
        if (!e)
            return "";
        if (typeof e.key === "string" && e.key !== "")
            return e.key;
        if (e.entry)
            return "app:" + (e.entry.id ?? e.name);
        return "bin:" + e.name;
    }
    function sortScored(out: var): void {
        out.sort((a, b) => (a.score - b.score) || ((b.use ?? 0) - (a.use ?? 0)) || ((b.last ?? 0) - (a.last ?? 0)) || ((a.ln ?? "") < (b.ln ?? "") ? -1 : (a.ln ?? "") > (b.ln ?? "") ? 1 : 0));
    }
    function refilterApps(q: string): void {
        const apps = root.appsCache ?? [];
        const out = [];
        const empty = q === "";
        for (const app of apps) {
            const name = app.name ?? app.genericName ?? "";
            if (name === "")
                continue;
            let best = 4;
            if (empty) {
                best = 1;
            } else {
                best = root.matchScore(String(app.name ?? ""), q);
                if (best !== 0)
                    best = Math.min(best, root.matchScore(String(app.genericName ?? ""), q));
                if (best !== 0)
                    best = Math.min(best, root.matchScore(String(app.comment ?? ""), q));
                if (best !== 0) {
                    const kws = app.keywords ?? [];
                    for (const h of kws) {
                        best = Math.min(best, root.matchScore(String(h ?? ""), q));
                        if (best === 0)
                            break;
                    }
                }
            }
            if (best < 4) {
                const appKey = "app:" + (app.id ?? name);
                out.push({name: name, ln: String(name ?? "").toLowerCase(), key: appKey, entry: app, score: best, use: Services.LaunchHistory.countFor(appKey), last: Services.LaunchHistory.lastFor(appKey)});
            }
        }
        root.sortScored(out);
        root.applyResults(out.slice(0, Services.Theme.resultMax));
    }
    function refilterRun(q: string): void {
        const out = [];
        const seen = new Set();
        for (const b of Services.RunMode.binaries ?? []) {
            const score = root.matchScoreLn(b.ln ?? "", q);
            if (score < 4) {
                seen.add(b.name);
                out.push({name: b.name, ln: b.ln ?? "", key: "bin:" + b.name, score: score, use: Services.LaunchHistory.countFor("bin:" + b.name), last: Services.LaunchHistory.lastFor("bin:" + b.name)});
            }
        }
        for (const c of Services.LaunchHistory.recentCmds(root.runQuery, 5)) {
            if (!seen.has(c.name)) {
                seen.add(c.name);
                out.push({name: c.name, ln: c.name.toLowerCase(), key: c.key, score: 1, use: c.use, last: c.last, isCmd: true});
            }
        }
        root.sortScored(out);
        root.applyResults(out.slice(0, Services.Theme.resultMax));
    }
    function applyResults(out: var): void {
        let idx = 0;
        if (root.selMoved) {
            const keep = root.entryKey(root.entries[resultList.currentIndex]);
            if (keep !== "") {
                const found = out.findIndex(e => root.entryKey(e) === keep);
                if (found >= 0)
                    idx = found;
            }
        }
        root.entries = out;
        if (out.length > 0) {
            resultList.currentIndex = Math.min(idx, out.length - 1);
            resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
        } else {
            resultList.currentIndex = -1;
        }
    }
    function launch(): void {
        root.flushRefilter();
        if (root.runMode) {
            const rest = String(queryField.text ?? "").trim().slice(1).trim();
            const sel = root.entries[resultList.currentIndex] ?? null;
            if (root.selMoved && sel) {
                if (sel.isCmd) {
                    Services.LaunchHistory.record(sel.key);
                    root.run(["sh", "-c", sel.name]);
                } else {
                    Services.LaunchHistory.record("bin:" + sel.name);
                    root.run([sel.name]);
                }
                return;
            }
            if (rest === "") {
                const picked = sel;
                if (!picked)
                    return;
                if (picked.isCmd) {
                    Services.LaunchHistory.record(picked.key);
                    root.run(["sh", "-c", picked.name]);
                } else {
                    Services.LaunchHistory.record("bin:" + picked.name);
                    root.run([picked.name]);
                }
                return;
            }
            const app = root.findApp(rest);
            if (app) {
                Services.LaunchHistory.record("app:" + (app.id ?? ""));
                root.runApp(app);
            } else {
                Services.LaunchHistory.record("cmd:" + rest);
                root.run(["sh", "-c", rest]);
            }
            return;
        }
        const entry = root.entries[resultList.currentIndex];
        if (!entry || !entry.entry)
            return;
        Services.LaunchHistory.record(entry.key ?? ("app:" + (entry.entry.id ?? entry.name ?? "")));
        root.runApp(entry.entry);
    }
    function findApp(rest: string): var {
        if (/\s/.test(rest))
            return null;
        const q = String(rest ?? "").toLowerCase();
        const cache = root.appsCache ?? [];
        for (const app of cache) {
            if (!app)
                continue;
            const rawCmd = Array.isArray(app.command) ? app.command : (typeof app.command === "string" ? [app.command] : []);
            const cmd = rawCmd.length > 0 ? rawCmd[0] : "";
            const base = String(cmd).split("/").pop().toLowerCase();
            if (base !== "" && base === q)
                return app;
            if (String(app.name ?? "").toLowerCase() === q)
                return app;
        }
        for (const app of cache) {
            if (!app)
                continue;
            const rawCmd = Array.isArray(app.command) ? app.command : (typeof app.command === "string" ? [app.command] : []);
            const cmd = rawCmd.length > 0 ? rawCmd[0] : "";
            const base = String(cmd).split("/").pop().toLowerCase();
            if (base !== "" && base.startsWith(q))
                return app;
            if (String(app.name ?? "").toLowerCase().startsWith(q))
                return app;
        }
        return null;
    }
    function asList(v): var {
        if (v === null || v === undefined)
            return [];
        if (typeof v === "string")
            return [v];
        if (Array.isArray(v))
            return v.slice();
        if (typeof v.length === "number") {
            const out = [];
            for (let i = 0; i < v.length; ++i)
                out.push(v[i]);
            return out;
        }
        return [v];
    }
    function sanitizeExec(cmd: var): var {
        const out = [];
        for (const a of root.asList(cmd)) {
            if (typeof a !== "string")
                continue;
            if (/^%(f|F|u|U|d|D|n|N|i|c|k|v|m)$/.test(a))
                continue;
            let b = a.replace(/%%/g, "%");
            const attached = b.match(/^(.*)=%[a-zA-Z]$/);
            if (attached)
                b = attached[1] + "=";
            if (b === "")
                continue;
            out.push(b);
        }
        return out;
    }
    function runApp(entry: var): void {
        if (!entry || !entry.command)
            return;
        const cmd = root.sanitizeExec(entry.command);
        if (cmd.length === 0)
            return;
        if (!entry.runInTerminal) {
            root.run(cmd);
            return;
        }
        const term = Quickshell.env("TERMINAL") ?? "kitty";
        root.run([term].concat(cmd));
    }
    function run(cmd: var): void {
        bar.closePopups();
        Quickshell.execDetached(cmd);
    }
    PopupCard {
        Rectangle {
            width: parent.width
            height: Services.Theme.rowHeight
            color: "transparent"
            border.width: 1
            border.color: root.runMode ? Services.Theme.accent : Services.Theme.border
            TextInput {
                id: queryField
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                verticalAlignment: TextInput.AlignVCenter
                color: Services.Theme.fg
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px13
                onTextChanged: {
                    root.selMoved = false;
                    refilterTimer.restart();
                }
                Keys.onUpPressed: root.stepSelection(-1)
                Keys.onDownPressed: root.stepSelection(1)
                Keys.onReturnPressed: root.launch()
                Keys.onEnterPressed: root.launch()
            }
        }
        ListView {
            id: resultList
            width: parent.width
            height: Services.Theme.listHeight(Services.Theme.listVisible)
            clip: true
            model: root.entries
            spacing: Services.Theme.listSpacing
            onCountChanged: clampListView(resultList)
            delegate: ResultRow {
                required property var modelData
                required property int index
                selected: resultList.currentIndex === index
                onHovered: {
                    resultList.currentIndex = index;
                    resultList.positionViewAtIndex(index, ListView.Contain);
                    root.selMoved = true;
                }
                onClicked: {
                    resultList.currentIndex = index;
                    root.selMoved = true;
                    root.launch();
                }
                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    width: parent.width - 20
                    textFormat: Text.RichText
                    text: (modelData.isCmd ? "> " : "") + root.hlName(modelData.name, root.hlQuery())
                    color: parent.selected ? Services.Theme.onAccent : parent.isHovered ? Services.Theme.fg : Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    elide: Text.ElideRight
                }
            }
        }
        HintText {
            id: hint
            text: "Tab move · Enter launch · > command"
        }
    }
}
