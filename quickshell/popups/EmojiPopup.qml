import QtQuick
import Quickshell
import "../components"
import "../services" as Services
import "../emoji/emoji.js" as EmojiData
import "../Palette.js" as Palette
BasePopup {
    id: root
    anchorMode: "center"
    implicitWidth: Palette.launcherWidth
    implicitHeight: 16 + Palette.rowHeight + Palette.popupSpacing * 2 + resultGrid.cellHeight * root.gridRows + hint.implicitHeight
    readonly property int gridCols: 10
    readonly property int gridRows: 9
    Shortcut {
        sequence: "Escape"
        enabled: root.visible && !queryField.activeFocus
        onActivated: root.close()
    }
    Shortcut { sequence: "Down"; enabled: root.visible && !queryField.activeFocus; onActivated: root.stepSelection(1, root.gridCols) }
    Shortcut { sequence: "Up"; enabled: root.visible && !queryField.activeFocus; onActivated: root.stepSelection(-1, root.gridCols) }
    Shortcut { sequence: "Left"; enabled: root.visible && !queryField.activeFocus; onActivated: root.stepSelection(-1, 1) }
    Shortcut { sequence: "Right"; enabled: root.visible && !queryField.activeFocus; onActivated: root.stepSelection(1, 1) }
    Shortcut { sequence: "Return"; enabled: root.visible && !queryField.activeFocus; onActivated: root.pick() }
    Shortcut { sequence: "Enter"; enabled: root.visible && !queryField.activeFocus; onActivated: root.pick() }
    Shortcut { sequence: "/"; enabled: root.visible && !queryField.activeFocus; onActivated: queryField.forceActiveFocus() }
    Shortcut { sequence: "j"; enabled: root.visible && !queryField.activeFocus; onActivated: root.stepSelection(1, root.gridCols) }
    Shortcut { sequence: "k"; enabled: root.visible && !queryField.activeFocus; onActivated: root.stepSelection(-1, root.gridCols) }
    Shortcut { sequence: "h"; enabled: root.visible && !queryField.activeFocus; onActivated: root.stepSelection(-1, 1) }
    Shortcut { sequence: "l"; enabled: root.visible && !queryField.activeFocus; onActivated: root.stepSelection(1, 1) }
    Shortcut { sequence: "Tab"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Ctrl+N"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Ctrl+P"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    property var entries: []
    property bool selMoved: false
    function groupRank(g: int): int {
        return [0, 1, 0, 2, 3, 4, 5, 6, 7, 8][g] ?? 99;
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
            queryField.text = "";
            root.selMoved = false;
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
        root.flushRefilter();
        if (resultGrid.count === 0)
            return;
        resultGrid.currentIndex = Palette.clamp(resultGrid.currentIndex + dir * (stride ?? 1), 0, resultGrid.count - 1);
        resultGrid.positionViewAtIndex(resultGrid.currentIndex, GridView.Contain);
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
    function refilter(): void {
        const q = String(queryField.text ?? "").toLowerCase().trim();
        const main = [];
        for (const e of EmojiData.EMOJI) {
            const score = root.matchScoreLn(e[2], q);
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
    function entryFor(ch: string): var {
        for (const e of EmojiData.EMOJI) {
            if (e[0] === ch)
                return e;
        }
        return null;
    }
    function applyResults(out: var): void {
        let idx = 0;
        if (root.selMoved) {
            const keep = (root.entries[resultGrid.currentIndex] ?? {}).key ?? "";
            if (keep !== "") {
                const found = out.findIndex(e => e.key === keep);
                if (found >= 0)
                    idx = found;
            }
        }
        root.entries = out;
        if (out.length > 0) {
            resultGrid.currentIndex = Math.min(idx, out.length - 1);
            resultGrid.positionViewAtIndex(resultGrid.currentIndex, GridView.Contain);
        } else {
            resultGrid.currentIndex = -1;
        }
    }
    function pick(): void {
        root.flushRefilter();
        const entry = root.entries[resultGrid.currentIndex];
        if (!entry)
            return;
        Services.EmojiHistory.record(entry.ch);
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy; printf %s "$1" | cliphist store', "qs", entry.ch]);
        Services.Notifs.notify({app: "emoji", summary: "Copied " + entry.ch + " " + entry.name, syncId: "emoji", timeout: Palette.osdTimeout});
        bar.closePopups();
    }
    PopupCard {
        Rectangle {
            width: parent.width
            height: Palette.rowHeight
            color: "transparent"
            border.width: 1
            border.color: Palette.border
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
                Keys.onUpPressed: root.stepSelection(-1, root.gridCols)
                Keys.onDownPressed: root.stepSelection(1, root.gridCols)
                Keys.onReturnPressed: root.pick()
                Keys.onEnterPressed: root.pick()
                Keys.onEscapePressed: queryField.focus = false
            }
        }
        GridView {
            id: resultGrid
            width: parent.width
            height: cellHeight * root.gridRows
            clip: true
            model: root.entries
            cellWidth: width / root.gridCols
            cellHeight: 42
            onCountChanged: {
                if (currentIndex >= count)
                    currentIndex = Math.max(0, count - 1);
            }
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool selected: resultGrid.currentIndex === index
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight
                color: selected ? Palette.accent : cellArea.containsMouse ? Palette.hoverBg : "transparent"
                MouseArea {
                    id: cellArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        resultGrid.currentIndex = index;
                        root.selMoved = true;
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
