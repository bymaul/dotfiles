pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: emojiHistory
    property var recents: []
    property bool loaded: false
    property bool loading: false
    property var pendingWrite: null
    readonly property string historyFile: {
        const xdg = Quickshell.env("XDG_DATA_HOME") ?? "";
        const home = Quickshell.env("HOME") ?? "";
        const base = xdg !== "" ? xdg : (home !== "" ? home + "/.local/share" : "/tmp/.local/share");
        return base + "/quickshell/emoji-recents.json";
    }
    function load(): void {
        if (emojiHistory.loaded || emojiHistory.loading)
            return;
        emojiHistory.loading = true;
        reader.running = true;
    }
    function record(ch: string): void {
        if (typeof ch !== "string" || ch === "")
            return;
        emojiHistory.recents = [ch].concat(emojiHistory.recents.filter(c => c !== ch)).slice(0, 30);
        const payload = JSON.stringify(emojiHistory.recents);
        if (writer.running) {
            emojiHistory.pendingWrite = payload;
            return;
        }
        writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s" "$1" > "$2"', "qs", payload, emojiHistory.historyFile];
        writer.running = true;
    }
    Process {
        id: reader
        command: ["cat", emojiHistory.historyFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const duringLoad = emojiHistory.recents.slice();
                try {
                    const arr = JSON.parse(text);
                    if (Array.isArray(arr)) {
                        const fromFile = arr.filter(c => typeof c === "string" && c !== "").slice(0, 30);
                        const seen = {};
                        const merged = [];
                        for (const c of duringLoad.concat(fromFile)) {
                            if (seen[c])
                                continue;
                            seen[c] = true;
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
            if (emojiHistory.loading) {
                emojiHistory.loading = false;
                emojiHistory.loaded = true;
            }
        }
    }
    Process {
        id: writer
        onExited: {
            if (emojiHistory.pendingWrite !== null) {
                const payload = emojiHistory.pendingWrite;
                emojiHistory.pendingWrite = null;
                writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s" "$1" > "$2"', "qs", payload, emojiHistory.historyFile];
                writer.running = true;
            }
        }
    }
}
