import QtQuick
import Quickshell
import Quickshell.Io

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
        writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s' + (newline ? '\\n' : '') + '" "$1" > "$2.tmp"; mv -f "$2.tmp" "$2"', "qs", text, file];
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
