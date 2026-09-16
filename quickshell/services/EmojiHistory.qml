pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: emojiHistory
    property var recents: []
    property bool loaded: false
    readonly property string historyFile: {
        const xdg = Quickshell.env("XDG_DATA_HOME") ?? "";
        const home = Quickshell.env("HOME") ?? "";
        const base = xdg !== "" ? xdg : (home !== "" ? home + "/.local/share" : "/tmp/.local/share");
        return base + "/quickshell/emoji-recents.json";
    }
    function load(): void {
        if (emojiHistory.loaded)
            return;
        emojiHistory.loaded = true;
        reader.running = true;
    }
    function record(ch: string): void {
        if (typeof ch !== "string" || ch === "")
            return;
        emojiHistory.recents = [ch].concat(emojiHistory.recents.filter(c => c !== ch)).slice(0, 30);
        writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s" "$1" > "$2"', "qs", JSON.stringify(emojiHistory.recents), emojiHistory.historyFile];
        writer.running = true;
    }
    Process {
        id: reader
        command: ["cat", emojiHistory.historyFile]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text);
                    if (Array.isArray(arr))
                        emojiHistory.recents = arr.filter(c => typeof c === "string" && c !== "").slice(0, 30);
                } catch (_) {}
            }
        }
    }
    Process {
        id: writer
    }
}
