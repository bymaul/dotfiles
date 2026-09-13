pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Palette.js" as Palette
Singleton {
    id: modes
    property bool caffeineActive: false
    property bool dndActive: false
    function toggleCaffeine(): void {
        modes.caffeineActive = !modes.caffeineActive;
        Notifs.notify({app: "caffeine", summary: modes.caffeineActive ? "Caffeine on" : "Caffeine off", syncId: "caffeine", timeout: Palette.osdTimeout});
    }
    function toggleDnd(): void {
        modes.dndActive = !modes.dndActive;
        Notifs.notify({app: "dnd", summary: modes.dndActive ? "DND on" : "DND off", syncId: "dnd", timeout: Palette.osdTimeout});
    }
    Process {
        id: inhibitProc
        command: ["systemd-inhibit", "--what=idle", "--who=Quickshell", "--why=Caffeine mode", "sleep", "infinity"]
        running: modes.caffeineActive
    }
    Process {
        id: staleLockCleanup
        command: ["sh", "-c", "pkill -f -- '[s]ystemd-inhibit.*--who=Quickshell.*sleep infinity'"]
        Component.onCompleted: staleLockCleanup.running = true
    }
}
