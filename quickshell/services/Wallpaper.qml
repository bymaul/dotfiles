pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Single-wallpaper resolver (no switcher by design).
// Per-screen windows in shell.qml bind to `source`.
Singleton {
    id: root
    property string source: ""
    property int probeIndex: 0
    readonly property var candidates: [Quickshell.env("HOME") + "/dotfiles/wallpapers/wallpaper.jpg", Quickshell.shellDir + "/wallpaper.jpg"]
    function probeNext(): void {
        if (root.probeIndex >= root.candidates.length) {
            console.warn("[wallpaper] no wallpaper found, tried: " + root.candidates.join(", "));
            return;
        }
        probe.command = ["test", "-f", root.candidates[root.probeIndex]];
        probe.running = true;
    }
    Process {
        id: probe
        onExited: exitCode => {
            if (exitCode === 0)
                root.source = "file://" + root.candidates[root.probeIndex];
            else {
                root.probeIndex++;
                root.probeNext();
            }
        }
        Component.onCompleted: root.probeNext()
    }
}
