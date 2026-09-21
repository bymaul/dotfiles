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
    readonly property string homeDir: Quickshell.env("HOME") ?? ""
    readonly property var candidates: {
        const out = [];
        if (root.homeDir !== "") {
            for (const ext of ["jpg", "jpeg", "png", "webp"]) {
                out.push(root.homeDir + "/dotfiles/wallpapers/wallpaper." + ext);
            }
            for (const ext of ["jpg", "jpeg", "png", "webp"]) {
                out.push(root.homeDir + "/Pictures/Wallpapers/wallpaper." + ext);
            }
        }
        out.push(Quickshell.shellDir + "/wallpaper.jpg");
        return out;
    }
    function probeNext(): void {
        if (probe.running)
            return;
        if (root.probeIndex >= root.candidates.length) {
            console.warn("[wallpaper] no wallpaper found, tried: " + root.candidates.join(", "));
            Notifs.notify({app: "wallpaper", summary: "No wallpaper found", body: "Add ~/dotfiles/wallpapers/wallpaper.jpg", syncId: "wallpaper", timeout: 8000});
            return;
        }
        probe.command = ["test", "-r", root.candidates[root.probeIndex]];
        probe.running = true;
    }
    // Called by Settings: explicit pick wins, empty resets to auto-probe.
    function applyOverride(path: string): void {
        if (path === "") {
            if (probe.running)
                probe.running = false;
            root.probeIndex = 0;
            root.source = "";
            root.probeNext();
        } else if (typeof path === "string" && path !== "") {
            if (probe.running)
                probe.running = false;
            root.source = "file://" + path;
        }
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
