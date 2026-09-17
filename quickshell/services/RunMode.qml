pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: runMode
    property var binaries: []
    property string lastPath: ""
    property double lastScan: 0
    readonly property int scanTtl: 60000
    function refresh(): void {
        if (scanner.running)
            return;
        const cur = Quickshell.env("PATH") ?? "";
        if (runMode.binaries.length > 0 && cur === runMode.lastPath && Date.now() - runMode.lastScan < runMode.scanTtl)
            return;
        runMode.lastPath = cur;
        runMode.lastScan = Date.now();
        scanner.running = true;
    }
    Process {
        id: scanner
        command: ["sh", "-c", "printf '%s' \"$PATH\" | tr ':' '\\n' | while read -r d; do [ -n \"$d\" ] && find \"$d\" -maxdepth 1 \\( -type f -o -type l \\) -perm /111 -printf '%f\\n' 2>/dev/null; done | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.trim().split("\n").filter(n => n !== "");
                runMode.binaries = names.map(n => ({name: n, ln: n.toLowerCase()}));
            }
        }
    }
}
