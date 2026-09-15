import QtQuick
import Quickshell
import "../components"
import "../services" as Services
import "../Palette.js" as Palette
BasePopup {
    id: root
    anchorMode: "center"
    implicitWidth: Palette.popupWidth
    implicitHeight: 16 + Palette.rowHeight + Palette.popupSpacing * 2 + Palette.listHeight(Palette.listVisible) + hint.implicitHeight
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
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
    readonly property bool runMode: String(queryField.text ?? "").trim().startsWith(">")
    readonly property string runQuery: String(queryField.text ?? "").trim().slice(1).trim().toLowerCase()
    onVisibleChanged: {
        if (visible) {
            root.appsCache = DesktopEntries.applications?.values ?? [];
            Services.RunMode.refresh();
            Services.LaunchHistory.load();
            queryField.text = "";
            root.refilter();
            queryField.forceActiveFocus();
            focusTimer.restart();
        } else {
            focusTimer.stop();
        }
    }
    // The focus grab activates ~grabDelay after show; re-assert text-field
    // focus after that so first keystrokes are never lost.
    Timer {
        id: focusTimer
        interval: Palette.focusDelay
        repeat: false
        onTriggered: {
            if (root.visible)
                queryField.forceActiveFocus();
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
        if (resultList.count === 0)
            return;
        resultList.currentIndex = Palette.clamp(resultList.currentIndex + dir, 0, resultList.count - 1);
        resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
    }
    function refilter(): void {
        if (root.runMode)
            root.refilterRun(root.runQuery);
        else
            root.refilterApps(String(queryField.text ?? "").toLowerCase().trim());
    }
    function matchScore(text: string, q: string): int {
        const t = String(text ?? "").toLowerCase();
        const query = String(q ?? "").toLowerCase();
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
    function sortScored(out: var): void {
        out.sort((a, b) => (a.score - b.score) || ((b.use ?? 0) - (a.use ?? 0)) || ((b.last ?? 0) - (a.last ?? 0)) || a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
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
                out.push({name: name, entry: app, score: best, use: Services.LaunchHistory.countFor("app:" + (app.id ?? "")), last: Services.LaunchHistory.lastFor("app:" + (app.id ?? ""))});
        }
        root.sortScored(out);
        root.applyResults(out);
    }
    function refilterRun(q: string): void {
        const out = [];
        for (const name of Services.RunMode.binaries ?? []) {
            const score = root.matchScore(String(name ?? ""), q);
            if (score < 3)
                out.push({name: name, score: score, use: Services.LaunchHistory.countFor("bin:" + name), last: Services.LaunchHistory.lastFor("bin:" + name)});
        }
        root.sortScored(out);
        root.applyResults(out);
    }
    function applyResults(out: var): void {
        root.entries = out;
        if (out.length > 0) {
            resultList.currentIndex = 0;
            resultList.positionViewAtIndex(0, ListView.Contain);
        } else {
            resultList.currentIndex = -1;
        }
    }
    function launch(): void {
        if (root.runMode) {
            const rest = queryField.text.trim().slice(1).trim();
            if (rest === "") {
                const picked = root.entries[resultList.currentIndex];
                if (picked) {
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
        for (const app of root.appsCache ?? []) {
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
        return null;
    }
    function runApp(entry: var): void {
        if (!entry || !entry.command)
            return;
        const cmd = Array.isArray(entry.command) ? entry.command : [entry.command];
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
                onTextChanged: root.refilter()
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
                border.width: selected ? 1 : 0
                border.color: selected ? Palette.accent : Palette.dim
                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        resultList.currentIndex = index;
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
                    text: modelData.name
                    color: selected ? Palette.onAccent : rowArea.containsMouse ? Palette.fg : Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                    elide: Text.ElideRight
                }
            }
        }
        HintText {
            id: hint
            text: "^n/^p move · ^y launch · > command"
        }
    }
}
