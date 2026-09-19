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
        if (scanner.running) {
            scanTimeout.restart();
            return;
        }
        const cur = Quickshell.env("PATH") ?? "";
        if (runMode.binaries.length > 0 && cur === runMode.lastPath && Date.now() - runMode.lastScan < runMode.scanTtl)
            return;
        runMode.lastPath = cur;
        runMode.lastScan = Date.now();
        scanner.running = true;
        scanTimeout.restart();
    }
    Process {
        id: scanner
        command: ["sh", "-c", "printf '%s' \"$PATH\" | tr ':' '\\n' | while IFS= read -r d; do [ -n \"$d\" ] && [ -d \"$d\" ] && find \"$d\" -maxdepth 1 \\( -type f -o -type l \\) -executable -printf '%f\\n' 2>/dev/null; done | sort -u | head -n 10000"]
        stdout: StdioCollector {
            onStreamFinished: {
                scanTimeout.stop();
                const names = text.trim().split("\n").filter(n => n !== "" && n.length < 256);
                runMode.binaries = names.map(n => ({name: n, ln: n.toLowerCase()}));
            }
        }
        onExited: exitCode => {
            scanTimeout.stop();
            if (exitCode !== 0 && runMode.binaries.length === 0)
                runMode.lastScan = 0;
        }
    }
    Timer {
        id: scanTimeout
        interval: 15000
        repeat: false
        onTriggered: {
            if (scanner.running)
                scanner.running = false;
        }
    }
}
