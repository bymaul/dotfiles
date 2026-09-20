import QtQuick
import Quickshell
import Quickshell.Io

// Single-flight atomic file writer with latest-wins coalescing.
// For simple overwrite payloads (history snapshots). Append-batch
// writers (LaunchHistory) and recompute-on-busy writers
// (Notifs, Settings) intentionally keep their own orchestration.
Item {
    id: root
    property bool busy: false
    property string currentFile: ""
    property string currentText: ""
    property bool currentNewline: true
    property string pendingFile: ""
    property string pendingText: ""
    property bool pendingNewline: true
    property bool hasPending: false
    signal wrote(string file, bool ok)
    function write(file: string, text: string, newline: bool): void {
        if (root.busy) {
            root.pendingFile = file;
            root.pendingText = text;
            root.pendingNewline = newline ?? true;
            root.hasPending = true;
            return;
        }
        root.start(file, text, newline ?? true);
    }
    function start(file: string, text: string, newline: bool): void {
        root.busy = true;
        root.currentFile = file;
        root.currentText = text;
        root.currentNewline = newline;
        writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s' + (newline ? '\\n' : '') + '" "$1" > "$2"', "qs", text, file];
        writer.running = true;
    }
    Process {
        id: writer
        onExited: exitCode => {
            if (root.hasPending) {
                const f = root.pendingFile;
                const t = root.pendingText;
                const n = root.pendingNewline;
                root.hasPending = false;
                root.start(f, t, n);
                return;
            }
            const f = root.currentFile;
            root.busy = false;
            root.wrote(f, exitCode === 0);
        }
    }
}
