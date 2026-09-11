pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for caffeine (idle inhibit) and DND.
// Bar icons and control-panel tiles bind to these properties. Every toggle
// flows through here (bar clicks, tiles, GlobalShortcuts), so state updates
// synchronously with zero polling.
Singleton {
    id: modes

    property bool caffeineActive: false
    property bool dndActive: false

    function toggleCaffeine(): void {
        modes.caffeineActive = !modes.caffeineActive
    }

    // Quickshell owns the inhibit lock directly: state IS the process.
    Process {
        id: inhibitLock

        command: [
            "systemd-inhibit",
            "--what=idle",
            "--who=Quickshell",
            "--why=Caffeine mode",
            "sleep",
            "infinity"
        ]

        running: modes.caffeineActive
    }

    onCaffeineActiveChanged: {
        if (modes.caffeineActive) {
            // Suspend hypridle so it doesn't override the inhibit lock.
            Quickshell.execDetached(["pkill", "hypridle"])
        } else {
            // inhibitLock.running follows caffeineActive via binding.
            Quickshell.execDetached(["hypridle"])
        }
    }

    // No confirmation toasts: the tiles already flip synchronously,
    // and a toast would race the state it announces.
    function toggleDnd(): void {
        modes.dndActive = !modes.dndActive
    }

    // Owned locks survive a quickshell crash; reap them on startup so a
    // fresh session never inherits a stuck inhibit.
    Process {
        id: staleLockCleanup

        command: [
            "sh", "-c",
            // [s] trick: keeps pkill from matching this wrapper's own cmdline.
            "pkill -f -- '[s]ystemd-inhibit.*--who=Quickshell.*sleep infinity'"
        ]

        Component.onCompleted: staleLockCleanup.running = true
    }
}
