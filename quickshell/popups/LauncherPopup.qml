import QtQuick
import Quickshell
import "../components"
import "../services" as Services
import "../Palette.js" as Palette
BasePopup {
    id: root
    anchorMode: "middle"
    focusTarget: queryField
    implicitWidth: Palette.launcherWidth
    implicitHeight: 16 + Palette.rowHeight + Palette.popupSpacing * 2 + Palette.listHeight(Palette.listVisible) + hint.implicitHeight
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }
    Shortcut {
        sequence: "q"
        enabled: root.visible && !queryField.activeFocus
        onActivated: root.close()
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
        if (resultList.count === 0)
            return;
        resultList.currentIndex = Palette.clamp(resultList.currentIndex + dir, 0, resultList.count - 1);
        resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
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
        interval: Palette.refilterDelay
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
    function matchScoreLn(t: string, query: string): int {
        if (query === "")
            return 1;
        if (t === query)
            return 0;
        if (t.startsWith(query))
            return 1;
        if (t.includes(query))
            return 2;
        return 3;
    }
    function matchScore(text: string, q: string): int {
        return root.matchScoreLn(String(text ?? "").toLowerCase(), String(q ?? "").toLowerCase());
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
        for (const app of apps) {
            const name = app.name ?? app.genericName ?? "";
            if (name === "")
                continue;
            const haystacks = [app.name ?? "", app.genericName ?? "", app.comment ?? ""].concat(app.keywords ?? []);
            let best = 3;
            for (const h of haystacks) {
                best = Math.min(best, root.matchScore(String(h ?? ""), q));
                if (best === 0)
                    break;
            }
            if (best < 3)
                out.push({name: name, ln: String(name ?? "").toLowerCase(), key: "app:" + (app.id ?? name), entry: app, score: best, use: Services.LaunchHistory.countFor("app:" + (app.id ?? "")), last: Services.LaunchHistory.lastFor("app:" + (app.id ?? ""))});
        }
        root.sortScored(out);
        root.applyResults(out.slice(0, Palette.resultMax));
    }
    function refilterRun(q: string): void {
        const out = [];
        for (const b of Services.RunMode.binaries ?? []) {
            const score = root.matchScoreLn(b.ln ?? "", q);
            if (score < 3)
                out.push({name: b.name, ln: b.ln ?? "", key: "bin:" + b.name, score: score, use: Services.LaunchHistory.countFor("bin:" + b.name), last: Services.LaunchHistory.lastFor("bin:" + b.name)});
        }
        root.sortScored(out);
        for (const c of Services.LaunchHistory.recentCmds(root.runQuery, 5)) {
            if (!out.some(e => e.name === c.name))
                out.push({name: c.name, ln: c.name.toLowerCase(), key: c.key, score: 1, use: c.use, last: c.last, isCmd: true});
        }
        root.sortScored(out);
        root.applyResults(out.slice(0, Palette.resultMax));
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
        if (!entry)
            return;
        Services.LaunchHistory.record("app:" + (entry.entry.id ?? ""));
        root.runApp(entry.entry);
    }
    function findApp(rest: string): var {
        if (/\s/.test(rest))
            return null;
        const q = String(rest ?? "").toLowerCase();
        const apps = [];
        for (const app of root.appsCache ?? []) {
            if (!app)
                continue;
            apps.push(app);
            const rawCmd = Array.isArray(app.command) ? app.command : (typeof app.command === "string" ? [app.command] : []);
            const cmd = rawCmd.length > 0 ? rawCmd[0] : "";
            const base = String(cmd).split("/").pop().toLowerCase();
            if (base !== "" && base === q)
                return app;
            if (String(app.name ?? "").toLowerCase() === q)
                return app;
        }
        for (const app of apps) {
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
        root.run(entry.runInTerminal ? ["kitty"].concat(cmd) : cmd);
    }
    function run(cmd: var): void {
        bar.closePopups();
        Quickshell.execDetached(cmd);
    }
    PopupCard {
        Rectangle {
            width: parent.width
            height: Palette.rowHeight
            color: "transparent"
            border.width: 1
            border.color: root.runMode ? Palette.accent : Palette.border
            TextInput {
                id: queryField
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                verticalAlignment: TextInput.AlignVCenter
                color: Palette.fg
                font.family: Palette.font
                font.pixelSize: Palette.px13
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
            height: Palette.listHeight(Palette.listVisible)
            clip: true
            model: root.entries
            spacing: Palette.listSpacing
            onCountChanged: {
                if (currentIndex >= count)
                    currentIndex = Math.max(0, count - 1);
            }
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool selected: resultList.currentIndex === index
                width: resultList.width
                height: Palette.rowHeight
                color: selected ? Palette.accent : rowArea.containsMouse ? Palette.hoverBg : "transparent"
                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: {
                        if (containsMouse) {
                            resultList.currentIndex = index;
                            resultList.positionViewAtIndex(index, ListView.Contain);
                            root.selMoved = true;
                        }
                    }
                    onClicked: {
                        resultList.currentIndex = index;
                        root.selMoved = true;
                        root.launch();
                    }
                }
                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    width: parent.width - 20
                    text: (modelData.isCmd ? "> " : "") + modelData.name
                    color: selected ? Palette.onAccent : rowArea.containsMouse ? Palette.fg : Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
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
