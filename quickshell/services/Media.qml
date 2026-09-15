pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "../Palette.js" as Palette
Singleton {
    id: media
    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    PwObjectTracker {
        objects: [media.sink, media.source]
    }
    property real brightness: 0
    property bool brightnessAvailable: true
    property bool brightnessPollEnabled: true
    function osd(opts): void {
        Notifs.notify(Object.assign({timeout: Palette.osdTimeout}, opts));
    }
    function volumeToast(): void {
        const audio = media.sink?.audio;
        const muted = audio?.muted ?? false;
        const pct = Math.round((audio?.volume ?? 0) * 100);
        if (muted) {
            media.osd({app: "volume", summary: "Muted", body: "Volume " + pct + "%", icon: "audio-volume-muted-symbolic", syncId: "volume"});
            return;
        }
        const icon = pct <= 33 ? "audio-volume-low-symbolic" : pct <= 66 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic";
        media.osd({app: "volume", summary: pct + "%", body: "Volume", icon: icon, value: pct, syncId: "volume"});
    }
    function micToast(): void {
        const muted = media.source?.audio?.muted ?? false;
        media.osd({app: "volume", summary: muted ? "Mic Muted" : "Mic", body: "Mic", icon: muted ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic"});
    }
    function brightnessToast(): void {
        const pct = Math.round(media.brightness);
        media.osd({app: "brightness", summary: pct + "%", body: "Brightness", icon: "display-brightness-symbolic", value: pct, syncId: "brightness"});
    }
    function adjustVolume(delta: real): void {
        const audio = media.sink?.audio;
        if (audio)
            audio.volume = Palette.clamp(audio.volume + delta, 0, Palette.volumeMax);
        media.volumeToast();
    }
    function volumeUp(): void {
        media.adjustVolume(Palette.volumeStep);
    }
    function volumeDown(): void {
        media.adjustVolume(-Palette.volumeStep);
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
        media.osd({app: "media", summary: player.trackTitle || "Unknown title", body: player.trackArtist || "", icon: "audio-x-generic-symbolic"});
    }
    Timer {
        id: mediaToastTimer
        interval: 400
        repeat: false
        onTriggered: media.mediaToast()
    }
    function transport(fn: string): void {
        const player = media.activePlayer();
        if (!player || typeof player[fn] !== "function")
            return;
        try {
            player[fn]();
        } catch (_) {
            return;
        }
        mediaToastTimer.restart();
    }
    function mediaToggle(): void {
        media.transport("togglePlaying");
    }
    function mediaNext(): void {
        media.transport("next");
    }
    function mediaPrev(): void {
        media.transport("previous");
    }
    function setBrightness(pct: real, quiet: bool): void {
        const clamped = Math.round(Palette.clamp(pct, Palette.brightnessMin, 100));
        media.brightness = clamped;
        media.brightnessPollEnabled = true;
        Quickshell.execDetached(["brightnessctl", "set", clamped + "%"]);
        if (!quiet)
            media.brightnessToast();
    }
    function brightnessUp(): void {
        media.setBrightness(media.brightness + Palette.brightnessStep, false);
    }
    function brightnessDown(): void {
        media.setBrightness(media.brightness - Palette.brightnessStep, false);
    }
    function markBrightnessUnavailable(): void {
        media.brightnessAvailable = false;
        media.brightnessPollEnabled = false;
    }
    Timer {
        id: brightnessPoll
        interval: 5000
        running: media.brightnessPollEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (media.brightnessAvailable)
                brightnessProbe.running = true;
        }
    }
    Process {
        id: brightnessProbe
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
