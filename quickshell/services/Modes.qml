pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: modes

    property bool caffeineActive: false
    property bool dndActive: false

    function toggleCaffeine(): void {
        modes.caffeineActive = !modes.caffeineActive;
        modes.caffeineToast();
    }

    function caffeineToast(): void {
        Quickshell.execDetached(["notify-send", "-a", "caffeine", "-t", "1500", "-h", "string:x-canonical-private-synchronous:caffeine", modes.caffeineActive ? "Caffeine on" : "Caffeine off"]);
    }

    Process {
        id: inhibitLock

        command: ["systemd-inhibit", "--what=idle", "--who=Quickshell", "--why=Caffeine mode", "sleep", "infinity"]

        running: modes.caffeineActive
    }

    onCaffeineActiveChanged: {
        if (modes.caffeineActive) {
            // hypridle would override the inhibit lock.
            Quickshell.execDetached(["pkill", "hypridle"]);
        } else {
            Quickshell.execDetached(["hypridle"]);
        }
    }

    function toggleDnd(): void {
        modes.dndActive = !modes.dndActive;
        modes.dndToast();
    }

    function dndToast(): void {
        Quickshell.execDetached(["notify-send", "-a", "dnd", "-t", "1500", "-h", "string:x-canonical-private-synchronous:dnd", modes.dndActive ? "DND on" : "DND off"]);
    }

    // Locks survive a crash; reap on startup so a fresh session
    // never inherits a stuck inhibit.
    Process {
        id: staleLockCleanup

        command: ["sh", "-c",
            // [s] keeps pkill from matching this wrapper's own cmdline.
            "pkill -f -- '[s]ystemd-inhibit.*--who=Quickshell.*sleep infinity'"]

        Component.onCompleted: staleLockCleanup.running = true
    }
}
