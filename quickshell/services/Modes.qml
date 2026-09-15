pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Palette.js" as Palette
Singleton {
    id: modes
    property bool caffeineActive: false
    property bool dndActive: false
    function setCaffeine(on: bool): void {
        modes.caffeineActive = on;
        Notifs.notify({app: "caffeine", summary: on ? "Caffeine on" : "Caffeine off", syncId: "caffeine", timeout: Palette.osdTimeout});
    }
    function toggleCaffeine(): void {
        if (!modes.caffeineActive) {
            caffeineCheck.running = true;
            return;
        }
        modes.setCaffeine(false);
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
        id: caffeineCheck
        command: ["sh", "-c", "command -v systemd-inhibit >/dev/null"]
        onExited: exitCode => {
            if (exitCode !== 0)
                Notifs.notify({app: "caffeine", summary: "Caffeine unavailable", body: "systemd-inhibit not found", timeout: Palette.osdTimeout});
            else
                modes.setCaffeine(true);
        }
    }
    Process {
        id: staleLockCleanup
        command: ["sh", "-c", "pkill -f -- '[s]ystemd-inhibit.*--who=Quickshell.*sleep infinity'"]
        Component.onCompleted: staleLockCleanup.running = true
    }
}
