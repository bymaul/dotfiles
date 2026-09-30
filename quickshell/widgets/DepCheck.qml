import QtQuick
import Quickshell
import Quickshell.Io

Process {
    id: root
    command: ["sh", "-c", "for b in cliphist wl-copy hyprctl jq brightnessctl notify-send systemd-inhibit hypridle upower loginctl btop; do command -v \"$b\" >/dev/null || printf '%s\\n' \"$b\"; done"]
    stdout: StdioCollector {
        onStreamFinished: {
            const missing = text.trim().split("\n").filter(s => s !== "");
            if (missing.length === 0)
                return;
            console.warn("quickshell: missing helper binaries: " + missing.join(", "));
            if (missing.includes("notify-send"))
                return;
            Quickshell.execDetached(["notify-send", "-a", "quickshell", "-t", "8000", "-i", "dialog-warning-symbolic", "Missing helper binaries", missing.join(", ")]);
        }
    }
    Component.onCompleted: root.running = true
}
