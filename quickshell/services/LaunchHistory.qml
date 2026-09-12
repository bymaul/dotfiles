pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: launchHistory

    // Counts shared by the launcher ranking. Keys: "app:<id>",
    // "bin:<name>", "cmd:<line>". File is append-mostly JSONL with
    // an occasional full rewrite past 1000 lines.
    property var counts: ({})
    property var pending: []
    property var retryQueue: []
    property var activeBatch: []
    property bool loaded: false
    property bool loading: false
    property bool rewriting: false

    readonly property string historyFile: {
        const xdg = Quickshell.env("XDG_DATA_HOME") ?? "";
        const base = xdg !== "" ? xdg : (Quickshell.env("HOME") ?? "") + "/.local/share";

        return base + "/quickshell/launch-history.jsonl";
    }

    function countFor(key: string): int {
        const e = launchHistory.counts[key];

        return e ? e.c : 0;
    }

    function lastFor(key: string): real {
        const e = launchHistory.counts[key];

        return e ? e.t : 0;
    }

    function record(key: string): void {
        const e = launchHistory.counts[key] ?? {
            c: 0,
            t: 0
        };

        e.c += 1;
        e.t = Date.now();
        launchHistory.counts[key] = e;
        launchHistory.capKeys();

        const line = JSON.stringify({
            k: key,
            t: e.t
        });

        if (launchHistory.loaded)
            launchHistory.appendLines([line]);
        else
            launchHistory.pending.push(line);
    }

    function load(): void {
        if (launchHistory.loaded || launchHistory.loading)
            return;
        launchHistory.loading = true;
        catProbe.running = true;
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

    function appendLines(lines: var): void {
        for (const l of lines)
            launchHistory.retryQueue.push(l);

        launchHistory.pumpWrites();
    }

    function pumpWrites(): void {
        if (writeProbe.running || launchHistory.retryQueue.length === 0)
            return;

        // Capped so a long queue can't blow ARG_MAX.
        launchHistory.activeBatch = launchHistory.retryQueue.slice(0, 50);
        launchHistory.retryQueue = launchHistory.retryQueue.slice(50);
        writeProbe.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s\\n" "$1" >> "$2"', "qs", launchHistory.activeBatch.join("\n"), launchHistory.historyFile];
        writeProbe.running = true;
    }

    function writeFull(): void {
        const lines = [];

        for (const k of Object.keys(launchHistory.counts)) {
            const e = launchHistory.counts[k];

            lines.push(JSON.stringify({
                k: k,
                c: e.c,
                t: e.t
            }));
        }

        launchHistory.rewriting = true;
        writeProbe.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s\\n" "$1" > "$2"', "qs", lines.join("\n"), launchHistory.historyFile];
        writeProbe.running = true;
    }

    Process {
        id: catProbe

        command: ["cat", launchHistory.historyFile]

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
                        const e = counts[r.k] ?? {
                            c: 0,
                            t: 0
                        };

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
        id: writeProbe

        onExited: exitCode => {
            if (exitCode !== 0) {
                // Requeue; the next record() retries (no tight loop).
                launchHistory.retryQueue = launchHistory.activeBatch.concat(launchHistory.retryQueue);
                launchHistory.activeBatch = [];
                launchHistory.rewriting = false;
                return;
            }

            launchHistory.activeBatch = [];

            if (launchHistory.rewriting)
                launchHistory.rewriting = false;

            launchHistory.pumpWrites();
        }
    }
}
