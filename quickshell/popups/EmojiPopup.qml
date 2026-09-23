import QtQuick
import Quickshell
import "../components"
import "../components/FilterUtils.js" as FilterUtils
import "../services" as Services
import "../emoji/emoji.js" as EmojiData
BasePopup {
    id: root
    anchorMode: "middle"
    implicitWidth: Services.Theme.settingsWidth
    implicitHeight: 16 + Services.Theme.rowHeight + Services.Theme.popupSpacing * 2 + resultGrid.cellHeight * root.gridRows + hint.implicitHeight
    readonly property int gridCols: 10
    readonly property int gridRows: 9
    function escArmed(): bool {
        return !search.hasFocus;
    }
    function quitArmed(): bool {
        return !search.hasFocus;
    }
    Shortcut { sequence: "Down"; enabled: root.visible && !search.hasFocus; onActivated: root.stepSelection(1, root.gridCols) }
    Shortcut { sequence: "Up"; enabled: root.visible && !search.hasFocus; onActivated: root.stepSelection(-1, root.gridCols) }
    Shortcut { sequence: "Left"; enabled: root.visible && !search.hasFocus; onActivated: root.stepSelection(-1, 1) }
    Shortcut { sequence: "Right"; enabled: root.visible && !search.hasFocus; onActivated: root.stepSelection(1, 1) }
    Shortcut { sequence: "Return"; enabled: root.visible && !search.hasFocus; onActivated: root.pick() }
    Shortcut { sequence: "Enter"; enabled: root.visible && !search.hasFocus; onActivated: root.pick() }
    Shortcut { sequence: "/"; enabled: root.visible && !search.hasFocus; onActivated: search.forceFocus() }
    Shortcut { sequence: "j"; enabled: root.visible && !search.hasFocus; onActivated: root.stepSelection(1, root.gridCols) }
    Shortcut { sequence: "k"; enabled: root.visible && !search.hasFocus; onActivated: root.stepSelection(-1, root.gridCols) }
    Shortcut { sequence: "h"; enabled: root.visible && !search.hasFocus; onActivated: root.stepSelection(-1, 1) }
    Shortcut { sequence: "l"; enabled: root.visible && !search.hasFocus; onActivated: root.stepSelection(1, 1) }
    Shortcut { sequence: "Tab"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Ctrl+N"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Ctrl+P"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    property var entries: []
    FilterState {
        id: filter
        onRefilterRequested: {
            if (root.visible)
                root.refilter();
        }
    }
    function groupRank(g: int): int {
        if (g < 0)
            return 99;
        if (g <= 1)
            return g;
        if (g === 2)
            return 0;
        if (g <= 9)
            return g - 1;
        return 99;
    }
    function groupName(g: int): string {
        return ["Smileys", "People", "", "Animals", "Food", "Travel", "Activities", "Objects", "Symbols", "Flags"][g] ?? "";
    }
    readonly property string selGroupName: {
        const e = root.entries[resultGrid.currentIndex] ?? null;
        const n = e ? root.groupName(e.g) : "";
        return n !== "" ? n : "Emoji";
    }
    onVisibleChanged: {
        if (visible) {
            Services.EmojiHistory.load();
            search.text = "";
            filter.selMoved = false;
            root.refilter();
        }
    }
    Connections {
        target: Services.EmojiHistory
        function onRecentsChanged(): void {
            if (root.visible)
                root.refilter();
        }
    }
    function stepSelection(dir: int, stride: int): void {
        filter.flush();
        stepListView(resultGrid, dir, stride);
        filter.selMoved = true;
    }
    function refilter(): void {
        const q = String(search.text ?? "").toLowerCase().trim();
        const main = [];
        for (const e of EmojiData.EMOJI) {
            const score = FilterUtils.matchScoreLn(e[2], q);
            if (score < 3)
                main.push({ch: e[0], name: e[1], g: e[3], key: e[0], score: q === "" ? 1 : score});
        }
        main.sort((a, b) => (a.score - b.score) || (root.groupRank(a.g) - root.groupRank(b.g)) || ((a.name < b.name) ? -1 : (a.name > b.name) ? 1 : 0));
        let out = main;
        if (q === "") {
            const seen = {};
            const head = [];
            for (const ch of Services.EmojiHistory.recents) {
                if (seen[ch])
                    continue;
                seen[ch] = true;
                const e = root.entryFor(ch);
                if (e)
                    head.push({ch: ch, name: e[1], g: e[3], key: ch, score: 0});
            }
            out = head.concat(main.filter(m => !seen[m.ch]));
        }
        root.applyResults(out);
    }
    property var emojiByChar: null
    function entryFor(ch: string): var {
        if (!root.emojiByChar) {
            const m = {};
            for (const e of EmojiData.EMOJI)
                m[e[0]] = e;
            root.emojiByChar = m;
        }
        return root.emojiByChar[ch] ?? null;
    }
    function applyResults(out: var): void {
        const idx = filter.keptIndex((root.entries[resultGrid.currentIndex] ?? {}).key ?? "", out);
        root.entries = out;
        if (out.length > 0) {
            resultGrid.currentIndex = Math.min(idx, out.length - 1);
            resultGrid.positionViewAtIndex(resultGrid.currentIndex, GridView.Contain);
        } else {
            resultGrid.currentIndex = -1;
        }
    }
    function pick(): void {
        filter.flush();
        const entry = root.entries[resultGrid.currentIndex];
        if (!entry)
            return;
        Services.EmojiHistory.record(entry.ch);
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy; printf %s "$1" | cliphist store', "qs", entry.ch]);
        Services.Notifs.notify({app: "emoji", summary: "Copied " + entry.ch + " " + entry.name, syncId: "emoji", timeout: Services.Theme.osdTimeout});
        bar.closePopups();
    }
    PopupCard {
        SearchField {
            id: search
            catchEscape: true
            onTextChanged: filter.schedule()
            onUpPressed: root.stepSelection(-1, root.gridCols)
            onDownPressed: root.stepSelection(1, root.gridCols)
            onAccepted: root.pick()
            onEscapePressed: search.releaseFocus()
        }
        GridView {
            id: resultGrid
            width: parent.width
            height: cellHeight * root.gridRows
            clip: true
            model: root.entries
            cellWidth: width / root.gridCols
            cellHeight: 42
            onCountChanged: clampListView(resultGrid)
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool selected: resultGrid.currentIndex === index
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight
                color: selected ? Services.Theme.accent : cellArea.containsMouse ? Services.Theme.hoverBg : Services.Theme.transparent
                MouseArea {
                    id: cellArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: {
                        if (containsMouse) {
                            resultGrid.currentIndex = index;
                            resultGrid.positionViewAtIndex(index, GridView.Contain);
                            filter.selMoved = true;
                        }
                    }
                    onClicked: {
                        resultGrid.currentIndex = index;
                        filter.selMoved = true;
                        root.pick();
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: modelData.ch
                    font.family: "Noto Color Emoji"
                    font.pixelSize: 24
                }
            }
        }
        HintText {
            id: hint
            text: root.selGroupName + " · / find · hjkl · ↵ copy"
        }
    }
}
