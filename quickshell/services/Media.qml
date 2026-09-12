pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

// Media state + feedback toasts (replaces osd-volume/osd-brightness).
// The control panel sliders and all media keys drive through here, so
// panel, bar icon, and toasts can never disagree. Toast contract mirrors
// the old scripts exactly (app names, int:value progress, synchronous
// replace ids), only the transport changed from notify-send-in-bash to
// notify-send-from-QML.
Singleton {
    id: media

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource

    // Touch Mpris at startup so its player list is already warm on
    // the first media key (singletons start on first access).
    property var _mprisPlayers: Mpris.players

    PwObjectTracker {
        objects: [media.sink, media.source]
    }

    property real brightness: 0
    property bool brightnessAvailable: true

    function volumeToast(): void {
        const audio = media.sink?.audio
        const muted = audio?.muted ?? false
        const pct = Math.round((audio?.volume ?? 0) * 100)

        if (muted) {
            Quickshell.execDetached([
                "notify-send", "-a", "volume", "-t", "1500",
                "-i", "audio-volume-muted-symbolic",
                "-h", "string:x-canonical-private-synchronous:volume",
                "Muted", "Volume " + pct + "%"
            ])
            return
        }

        const icon = pct <= 33 ? "audio-volume-low-symbolic"
            : pct <= 66 ? "audio-volume-medium-symbolic"
            : "audio-volume-high-symbolic"

        Quickshell.execDetached([
            "notify-send", "-a", "volume", "-t", "1500",
            "-i", icon, "-h", "int:value:" + pct,
            "-h", "string:x-canonical-private-synchronous:volume",
            pct + "%", "Volume"
        ])
    }

    function micToast(): void {
        const muted = media.source?.audio?.muted ?? false

        Quickshell.execDetached([
            "notify-send", "-a", "volume", "-t", "1500",
            "-i", muted ? "microphone-sensitivity-muted-symbolic"
                : "microphone-sensitivity-high-symbolic",
            "-h", "string:x-canonical-private-synchronous:volume",
            muted ? "Mic Muted" : "Mic"
        ])
    }

    function brightnessToast(): void {
        const pct = Math.round(media.brightness)

        Quickshell.execDetached([
            "notify-send", "-a", "brightness", "-t", "1500",
            "-i", "display-brightness-symbolic",
            "-h", "int:value:" + pct,
            "-h", "string:x-canonical-private-synchronous:brightness",
            pct + "%", "Brightness"
        ])
    }

    function volumeUp(): void {
        const audio = media.sink?.audio

        if (audio)
            audio.volume = Math.min(1.5, audio.volume + 0.05)

        media.volumeToast()
    }

    function volumeDown(): void {
        const audio = media.sink?.audio

        if (audio)
            audio.volume = Math.max(0, audio.volume - 0.05)

        media.volumeToast()
    }

    function toggleVolumeMute(): void {
        const audio = media.sink?.audio

        if (audio)
            audio.muted = !audio.muted

        media.volumeToast()
    }

    function toggleMicMute(): void {
        const audio = media.source?.audio

        if (audio)
            audio.muted = !audio.muted

        media.micToast()
    }

    // Player pick mirrors playerctl: the playing one, else the first.
    function activePlayer(): var {
        let first = null

        for (const player of Mpris.players?.values ?? []) {
            if (!first)
                first = player

            if (player.isPlaying)
                return player
        }

        return first
    }

    function mediaToast(): void {
        const player = media.activePlayer()

        if (!player)
            return

        Quickshell.execDetached([
            "notify-send", "-a", "media", "-t", "1500",
            "-i", "audio-x-generic-symbolic",
            "-h", "string:x-canonical-private-synchronous:media",
            player.trackTitle || "Unknown title",
            player.trackArtist || ""
        ])
    }

    // MPRIS round-trips over dbus, so the toast waits a beat for the
    // new track state instead of announcing the stale one.
    Timer {
        id: mediaToastTimer

        interval: 400
        repeat: false

        onTriggered: media.mediaToast()
    }

    function mediaToggle(): void {
        const player = media.activePlayer()

        if (!player)
            return

        player.togglePlaying()
        mediaToastTimer.restart()
    }

    function mediaNext(): void {
        const player = media.activePlayer()

        if (!player)
            return

        player.next()
        mediaToastTimer.restart()
    }

    function mediaPrev(): void {
        const player = media.activePlayer()

        if (!player)
            return

        player.previous()
        mediaToastTimer.restart()
    }

    // quiet = true when the caller already shows the value itself
    // (control panel slider); the toast would just double it.
    function setBrightness(pct: real, quiet: bool): void {
        // Floor at 5%: brightnessctl accepts 0%, which turns the
        // backlight fully off and leaves a black screen.
        const clamped = Math.max(5, Math.min(100, Math.round(pct)))

        brightness = clamped

        Quickshell.execDetached([
            "brightnessctl",
            "set",
            clamped + "%"
        ])

        if (!quiet)
            media.brightnessToast()
    }

    function brightnessUp(): void {
        media.setBrightness(media.brightness + 5, false)
    }

    function brightnessDown(): void {
        media.setBrightness(media.brightness - 5, false)
    }

    Timer {
        id: brightnessPoll

        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            if (media.brightnessAvailable)
                brightnessProbe.running = true
        }
    }

    Process {
        id: brightnessProbe

        // Routed through sh so a missing brightnessctl binary still
        // yields a reliable nonzero exit (QProcess start failures
        // don't guarantee onExited).
        command: [
            "sh",
            "-c",
            "command -v brightnessctl >/dev/null && brightnessctl -m || exit 1"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.split(",")

                if (fields.length >= 4) {
                    media.brightness = parseFloat(fields[3]) || 0
                    media.brightnessAvailable = true
                } else {
                    media.brightnessAvailable = false
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0)
                media.brightnessAvailable = false
        }
    }
}
