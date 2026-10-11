pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: emojiHistory
    property var recents: []
    property bool loaded: false
    property bool loading: false
    property bool loadDone: false
    readonly property string historyFile: {
        const xdg = Quickshell.env("XDG_DATA_HOME") ?? "";
        const home = Quickshell.env("HOME") ?? "";
        if (xdg !== "")
            return xdg + "/quickshell/emoji-recents.json";
        if (home !== "")
            return home + "/.local/share/quickshell/emoji-recents.json";
        return "";
    }
    function load(): void {
        if (emojiHistory.loaded || emojiHistory.loading)
            return;
        if (emojiHistory.historyFile === "")
            return;
        emojiHistory.loading = true;
        reader.running = true;
    }
    function record(ch: string): void {
        if (typeof ch !== "string" || ch === "" || ch.length > 32)
            return;
        if (emojiHistory.historyFile === "")
            return;
        emojiHistory.recents = [ch].concat(emojiHistory.recents.filter(c => c !== ch)).slice(0, 30);
        writer.write(emojiHistory.historyFile, JSON.stringify(emojiHistory.recents), false);
    }
    AtomicWriter {
        id: writer
    }
    Process {
        id: reader
        command: ["cat", emojiHistory.historyFile]
        stdout: StdioCollector {
            onStreamFinished: {
                if (emojiHistory.loadDone)
                    return;
                emojiHistory.loadDone = true;
                const duringLoad = emojiHistory.recents.slice();
                try {
                    if (text.length > 65536)
                        throw "history file too large";
                    const arr = JSON.parse(text);
                    if (Array.isArray(arr)) {
                        const fromFile = arr.filter(c => typeof c === "string" && c !== "" && c.length <= 32).slice(0, 30);
                        const seen = new Set();
                        const merged = [];
                        for (const c of duringLoad.concat(fromFile)) {
                            if (seen.has(c))
                                continue;
                            seen.add(c);
                            merged.push(c);
                            if (merged.length >= 30)
                                break;
                        }
                        emojiHistory.recents = merged;
                    }
                } catch (_) {
                    if (duringLoad.length > 0)
                        emojiHistory.recents = duringLoad.slice(0, 30);
                }
                emojiHistory.loading = false;
                emojiHistory.loaded = true;
            }
        }
        onExited: exitCode => {
            if (emojiHistory.loadDone)
                return;
            emojiHistory.loadDone = true;
            if (emojiHistory.loading) {
                emojiHistory.loading = false;
                emojiHistory.loaded = true;
            }
        }
    }
}
