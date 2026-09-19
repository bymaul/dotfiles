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
        if (!audio) {
            media.osd({app: "volume", summary: "No audio device", body: "Volume unavailable", icon: "audio-volume-muted-symbolic", syncId: "volume"});
            return;
        }
        const muted = audio.muted ?? false;
        const pct = Math.round((audio.volume ?? 0) * 100);
        if (muted) {
            media.osd({app: "volume", summary: "Muted", body: "Volume " + pct + "%", icon: "audio-volume-muted-symbolic", syncId: "volume"});
            return;
        }
        const icon = pct <= 33 ? "audio-volume-low-symbolic" : pct <= 66 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic";
        media.osd({app: "volume", summary: pct + "%", body: "Volume", icon: icon, value: pct, syncId: "volume"});
    }
    function micToast(): void {
        const audio = media.source?.audio;
        if (!audio) {
            media.osd({app: "volume", summary: "No mic device", body: "Mic unavailable", icon: "microphone-sensitivity-muted-symbolic", syncId: "mic"});
            return;
        }
        const muted = audio.muted ?? false;
        media.osd({app: "volume", summary: muted ? "Mic Muted" : "Mic", body: "Mic", icon: muted ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic", syncId: "mic"});
    }
    function brightnessToast(): void {
        if (!media.brightnessAvailable) {
            media.osd({app: "brightness", summary: "No display control", body: "Brightness unavailable", icon: "display-brightness-symbolic", syncId: "brightness"});
            return;
        }
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
        media.osd({app: "media", summary: player.trackTitle || "Unknown title", body: player.trackArtist || "", icon: "audio-x-generic-symbolic", syncId: "media"});
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
    property int pendingBrightness: -1
    function setBrightness(pct: real, quiet: bool): void {
        const clamped = Math.round(Palette.clamp(pct, Palette.brightnessMin, 100));
        media.brightness = clamped;
        media.brightnessPollEnabled = true;
        media.pendingBrightness = clamped;
        brightnessApply.restart();
        if (!quiet)
            media.brightnessToast();
    }
    Timer {
        id: brightnessApply
        interval: 120
        repeat: false
        onTriggered: {
            if (media.pendingBrightness < 0)
                return;
            const v = media.pendingBrightness;
            media.pendingBrightness = -1;
            Quickshell.execDetached(["brightnessctl", "set", v + "%"]);
        }
    }
    function brightnessUp(): void {
        media.setBrightness(media.brightness + Palette.brightnessStep, false);
    }
    function brightnessDown(): void {
        media.setBrightness(media.brightness - Palette.brightnessStep, false);
    }
    function markBrightnessUnavailable(): void {
        media.brightnessAvailable = false;
        media.brightnessPollEnabled = true;
    }
    Timer {
        id: brightnessPoll
        interval: 15000
        running: media.brightnessPollEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!brightnessProbe.running)
                brightnessProbe.running = true;
        }
    }
    Timer {
        id: brightnessRetry
        interval: 60000
        running: !media.brightnessAvailable
        repeat: true
        onTriggered: {
            if (!brightnessProbe.running)
                brightnessProbe.running = true;
        }
    }
    Process {
        id: brightnessProbe
        command: ["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m || exit 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = String(text ?? "").split("\n").map(l => l.trim()).filter(l => l !== "");
                const line = lines.find(l => l.includes(",backlight,")) ?? lines[0] ?? "";
                const fields = line.split(",");
                if (fields.length >= 4) {
                    const pct = parseFloat(fields[3]);
                    if (!isNaN(pct)) {
                        media.brightness = pct;
                        media.brightnessAvailable = true;
                        return;
                    }
                }
                media.markBrightnessUnavailable();
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                media.markBrightnessUnavailable();
        }
    }
}
