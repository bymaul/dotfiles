pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

Singleton {
    id: media

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource

    // Touch Mpris at startup so the player list is warm on the
    // first media key.
    property var _mprisPlayers: Mpris.players

    PwObjectTracker {
        objects: [media.sink, media.source]
    }

    property real brightness: 0
    property bool brightnessAvailable: true

    function volumeToast(): void {
        const audio = media.sink?.audio;
        const muted = audio?.muted ?? false;
        const pct = Math.round((audio?.volume ?? 0) * 100);

        if (muted) {
            Quickshell.execDetached(["notify-send", "-a", "volume", "-t", "1500", "-i", "audio-volume-muted-symbolic", "-h", "string:x-canonical-private-synchronous:volume", "Muted", "Volume " + pct + "%"]);
            return;
        }

        const icon = pct <= 33 ? "audio-volume-low-symbolic" : pct <= 66 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic";

        Quickshell.execDetached(["notify-send", "-a", "volume", "-t", "1500", "-i", icon, "-h", "int:value:" + pct, "-h", "string:x-canonical-private-synchronous:volume", pct + "%", "Volume"]);
    }

    function micToast(): void {
        const muted = media.source?.audio?.muted ?? false;

        Quickshell.execDetached(["notify-send", "-a", "volume", "-t", "1500", "-i", muted ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic", "-h", "string:x-canonical-private-synchronous:volume", muted ? "Mic Muted" : "Mic"]);
    }

    function brightnessToast(): void {
        const pct = Math.round(media.brightness);

        Quickshell.execDetached(["notify-send", "-a", "brightness", "-t", "1500", "-i", "display-brightness-symbolic", "-h", "int:value:" + pct, "-h", "string:x-canonical-private-synchronous:brightness", pct + "%", "Brightness"]);
    }

    function volumeUp(): void {
        const audio = media.sink?.audio;

        if (audio)
            audio.volume = Math.min(1.5, audio.volume + 0.05);

        media.volumeToast();
    }

    function volumeDown(): void {
        const audio = media.sink?.audio;

        if (audio)
            audio.volume = Math.max(0, audio.volume - 0.05);

        media.volumeToast();
    }

    function toggleVolumeMute(): void {
        const audio = media.sink?.audio;

        if (audio)
            audio.muted = !audio.muted;

        media.volumeToast();
    }

    function toggleMicMute(): void {
        const audio = media.source?.audio;

        if (audio)
            audio.muted = !audio.muted;

        media.micToast();
    }

    function activePlayer(): var {
        let first = null;

        for (const player of Mpris.players?.values ?? []) {
            if (!first)
                first = player;

            if (player.isPlaying)
                return player;
        }

        return first;
    }

    function mediaToast(): void {
        const player = media.activePlayer();

        if (!player)
            return;
        Quickshell.execDetached(["notify-send", "-a", "media", "-t", "1500", "-i", "audio-x-generic-symbolic", "-h", "string:x-canonical-private-synchronous:media", player.trackTitle || "Unknown title", player.trackArtist || ""]);
    }

    // MPRIS is async: wait a beat so the toast reports the new
    // track, not the stale one.
    Timer {
        id: mediaToastTimer

        interval: 400
        repeat: false

        onTriggered: media.mediaToast()
    }

    function mediaToggle(): void {
        const player = media.activePlayer();

        if (!player)
            return;
        player.togglePlaying();
        mediaToastTimer.restart();
    }

    function mediaNext(): void {
        const player = media.activePlayer();

        if (!player)
            return;
        player.next();
        mediaToastTimer.restart();
    }

    function mediaPrev(): void {
        const player = media.activePlayer();

        if (!player)
            return;
        player.previous();
        mediaToastTimer.restart();
    }

    // quiet: caller already shows the value (panel slider).
    function setBrightness(pct: real, quiet: bool): void {
        // Floor at 5%: 0% kills the backlight (black screen).
        const clamped = Math.max(5, Math.min(100, Math.round(pct)));

        brightness = clamped;

        // A manual set may follow a fresh install: retry the poller
        // even after it backed off.
        brightnessPoll.running = true;

        Quickshell.execDetached(["brightnessctl", "set", clamped + "%"]);

        if (!quiet)
            media.brightnessToast();
    }

    function brightnessUp(): void {
        media.setBrightness(media.brightness + 5, false);
    }

    function brightnessDown(): void {
        media.setBrightness(media.brightness - 5, false);
    }

    // Backoff: stop polling once unavailable; setBrightness restarts.
    function markBrightnessUnavailable(): void {
        media.brightnessAvailable = false;
        brightnessPoll.running = false;
    }

    Timer {
        id: brightnessPoll

        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            if (media.brightnessAvailable)
                brightnessProbe.running = true;
        }
    }

    Process {
        id: brightnessProbe

        // sh wrapper: a missing binary still yields nonzero exit
        // (QProcess start failures don't guarantee onExited).
        command: ["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m || exit 1"]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.split(",");

                if (fields.length >= 4) {
                    media.brightness = parseFloat(fields[3]) || 0;
                    media.brightnessAvailable = true;
                } else {
                    media.markBrightnessUnavailable();
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0)
                media.markBrightnessUnavailable();
        }
    }
}
