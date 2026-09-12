pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: runMode

    property var binaries: []

    function refresh(): void {
        probe.running = true;
    }

    Process {
        id: probe

        command: ["sh", "-c", "printf '%s' \"$PATH\" | tr ':' '\\n' | while read -r d; do [ -n \"$d\" ] && find \"$d\" -maxdepth 1 \\( -type f -o -type l \\) -perm /111 -printf '%f\\n' 2>/dev/null; done | sort -u"]

        stdout: StdioCollector {
            onStreamFinished: {
                runMode.binaries = text.trim().split("\n").filter(n => n !== "");
            }
        }
    }
}
