pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for caffeine (idle inhibit) and DND (mako mode).
// Bar icons and control-panel tiles bind to these properties. Every toggle
// flows through here (bar clicks, tiles, GlobalShortcuts), so state updates
// synchronously with zero polling.
//
// DND backend isolation: when mako is replaced by quickshell notifications,
// only the dndActive writer/reader below changes.
Singleton {
    id: modes

    property bool caffeineActive: false
    property bool dndActive: false

    function toggleCaffeine(): void {
        modes.caffeineActive = !modes.caffeineActive
    }

    function toggleDnd(): void {
        modes.dndActive = !modes.dndActive
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

    // NOTE: no notify-send confirmations here. The tiles and bar icons
    // already flip synchronously, and spawning a toast races the very state
    // it announces: the DND "On" toast maps just as mako applies the mode,
    // and its 1500ms map/unmap churn breaks the control panel's keyboard
    // grab, dismissing the panel ~1.5s after the click.
    onDndActiveChanged: {
        if (modes.dndActive) {
            Quickshell.execDetached(["makoctl", "mode", "-a", "dnd"])
        } else {
            Quickshell.execDetached(["makoctl", "mode", "-r", "dnd"])
        }
    }

    // One-shot init: pick up DND left enabled by a previous session.
    // (Caffeine always starts off; stale inhibit locks are cleaned below.)
    Process {
        id: dndInitProbe

        command: ["makoctl", "mode"]

        stdout: StdioCollector {
            onStreamFinished: {
                modes.dndActive = text.split("\n").some(
                    line => line.trim() === "dnd"
                )
            }
        }

        Component.onCompleted: dndInitProbe.running = true
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
