pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: launchHistory
    property var counts: ({})
    property var pending: []
    property var retryQueue: []
    property var activeBatch: []
    property bool loaded: false
    property bool loading: false
    property bool rewriting: false
    readonly property string historyFile: {
        const xdg = Quickshell.env("XDG_DATA_HOME") ?? "";
        const home = Quickshell.env("HOME") ?? "";
        const base = xdg !== "" ? xdg : (home !== "" ? home + "/.local/share" : "/tmp/.local/share");
        return base + "/quickshell/launch-history.jsonl";
    }
    function lookup(key: string): var {
        return launchHistory.counts[key] ?? {c: 0, t: 0};
    }
    function countFor(key: string): int {
        return launchHistory.lookup(key).c;
    }
    function lastFor(key: string): real {
        return launchHistory.lookup(key).t;
    }
    function record(key: string): void {
        const e = launchHistory.lookup(key);
        e.c += 1;
        e.t = Date.now();
        launchHistory.counts[key] = e;
        launchHistory.capKeys();
        const line = JSON.stringify({k: key, t: e.t});
        if (launchHistory.loaded)
            launchHistory.appendLines([line]);
        else
            launchHistory.pending.push(line);
    }
    function load(): void {
        if (launchHistory.loaded || launchHistory.loading)
            return;
        launchHistory.loading = true;
        reader.running = true;
    }
    function capKeys(): void {
        const keys = Object.keys(launchHistory.counts);
        if (keys.length <= 200)
            return;
        keys.sort((a, b) => {
            const ea = launchHistory.counts[a];
            const eb = launchHistory.counts[b];
            return (eb.c - ea.c) || (eb.t - ea.t);
        });
        for (const k of keys.slice(200))
            delete launchHistory.counts[k];
    }
    function writeCommand(lines: var, append: bool): var {
        return ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s\\n" "$1" ' + (append ? ">>" : ">") + ' "$2"', "qs", lines.join("\n"), launchHistory.historyFile];
    }
    function appendLines(lines: var): void {
        for (const l of lines)
            launchHistory.retryQueue.push(l);
        launchHistory.pumpWrites();
    }
    function pumpWrites(): void {
        if (writer.running || launchHistory.rewriting || launchHistory.retryQueue.length === 0)
            return;
        launchHistory.activeBatch = launchHistory.retryQueue.slice(0, 50);
        launchHistory.retryQueue = launchHistory.retryQueue.slice(50);
        writer.command = launchHistory.writeCommand(launchHistory.activeBatch, true);
        writer.running = true;
    }
    function writeFull(): void {
        const lines = [];
        for (const k of Object.keys(launchHistory.counts)) {
            const e = launchHistory.counts[k];
            lines.push(JSON.stringify({k: k, c: e.c, t: e.t}));
        }
        launchHistory.rewriting = true;
        writer.command = launchHistory.writeCommand(lines, false);
        writer.running = true;
    }
    Process {
        id: reader
        command: ["sh", "-c", 'tail -n 2000 "$1" 2>/dev/null || cat "$1" 2>/dev/null', "qs", launchHistory.historyFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const counts = launchHistory.counts;
                let lines = 0;
                for (const line of text.split("\n")) {
                    if (line.trim() === "")
                        continue;
                    lines += 1;
                    try {
                        const r = JSON.parse(line);
                        if (typeof r.k !== "string")
                            continue;
                        const e = counts[r.k] ?? {c: 0, t: 0};
                        e.c += (typeof r.c === "number" ? r.c : 1);
                        if (typeof r.t === "number" && r.t > e.t)
                            e.t = r.t;
                        counts[r.k] = e;
                    } catch (_) {}
                }
                launchHistory.capKeys();
                if (lines > 1000) {
                    launchHistory.pending = [];
                    launchHistory.writeFull();
                } else if (launchHistory.pending.length > 0) {
                    launchHistory.appendLines(launchHistory.pending);
                    launchHistory.pending = [];
                }
                launchHistory.loading = false;
                launchHistory.loaded = true;
            }
        }
    }
    Process {
        id: writer
        onExited: exitCode => {
            if (exitCode !== 0) {
                launchHistory.retryQueue = launchHistory.activeBatch.concat(launchHistory.retryQueue);
                launchHistory.activeBatch = [];
                launchHistory.rewriting = false;
                return;
            }
            launchHistory.activeBatch = [];
            launchHistory.rewriting = false;
            launchHistory.pumpWrites();
        }
    }
}
