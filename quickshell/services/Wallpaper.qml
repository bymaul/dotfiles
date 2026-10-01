pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property string source: ""
    property string override: ""
    property bool scanDone: false
    property bool notifiedEmpty: false

    // Called by Settings: explicit pick wins. Empty is legacy (pre-Auto-removal
    // settings.json) and falls back to the first scanned wallpaper until
    // Settings.ensureWallpaper() persists an explicit pick.
    function applyOverride(path: string): void {
        root.override = typeof path === "string" ? path : "";
        root.resolve();
    }

    // Single source of truth for discovery is Settings.wallpapers, which
    // scans ~/dotfiles/wallpapers and ~/Pictures/Wallpapers.
    function resolve(): void {
        if (root.override !== "") {
            root.notifiedEmpty = false;
            root.source = "file://" + root.override;
            return;
        }
        const first = Settings.wallpapers.length > 0 ? Settings.wallpapers[0] : "";
        if (first !== "") {
            root.notifiedEmpty = false;
            root.source = "file://" + first;
            return;
        }
        root.source = "";
        if (!root.scanDone || root.notifiedEmpty)
            return;
        root.notifiedEmpty = true;
        console.warn("[wallpaper] no wallpaper found");
        Notifs.notify({app: "wallpaper", summary: "No wallpaper found", body: "Add an image to ~/dotfiles/wallpapers or ~/Pictures/Wallpapers", syncId: "wallpaper", timeout: 8000});
    }

    Connections {
        target: Settings
        function onWallpapersChanged() {
            root.scanDone = true;
            if (root.override === "")
                root.resolve();
        }
    }
}
