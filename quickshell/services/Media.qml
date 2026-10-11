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
    PwObjectTracker {
        objects: [media.sink, media.source]
    }
    property real brightness: 0
    property bool brightnessAvailable: true
    property bool brightnessPollEnabled: false
    property int brightnessFailures: 0
    function osd(opts): void {
        Notifs.notify(Object.assign({timeout: Theme.osdTimeout}, opts));
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
    function adjustVolume(delta: real, quiet: bool): void {
        const audio = media.sink?.audio;
        if (audio)
            audio.volume = Theme.clamp((audio.volume ?? 0) + delta, 0, Theme.volumeMax);
        if (!quiet)
            media.volumeToast();
    }
    function volumeUp(): void {
        media.adjustVolume(Theme.volumeStep);
    }
    function volumeDown(): void {
        media.adjustVolume(-Theme.volumeStep);
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
    property string preferredPlayer: ""
    function rawPlayers(): var {
        return [...(Mpris.players?.values ?? [])];
    }
    function isUsable(p): bool {
        if (!p)
            return false;
        if (p.canControl === false)
            return false;
        if (p.isPlaying)
            return true;
        if ((p.trackTitle ?? "") !== "")
            return true;
        return p.playbackState !== undefined && p.playbackState !== MprisPlaybackState.Stopped;
    }
    function playerList(): var {
        return media._players;
    }
    function stablePlayers(): var {
        const list = media.rawPlayers().filter(p => media.isUsable(p));
        const playing = list.filter(p => p.isPlaying);
        const rest = list.filter(p => !p.isPlaying);
        const byBus = (a, b) => {
            const ka = a.dbusName ?? a.identity ?? "";
            const kb = b.dbusName ?? b.identity ?? "";
            return ka < kb ? -1 : ka > kb ? 1 : 0;
        };
        playing.sort(byBus);
        rest.sort(byBus);
        return [...playing, ...rest];
    }
    readonly property var _stable: {
        const list = media.stablePlayers();
        for (const p of list) {
            p.isPlaying;
            p.playbackState;
            p.trackTitle;
            p.canControl;
        }
        return list;
    }
    readonly property var _players: {
        const stable = media._stable;
        if (media.preferredPlayer !== "") {
            const preferred = stable.find(p => (p.dbusName ?? "") === media.preferredPlayer || (p.identity ?? "") === media.preferredPlayer);
            if (preferred)
                return [preferred, ...stable.filter(p => p !== preferred)];
        }
        return stable;
    }
    readonly property int usableCount: media._players.length
    readonly property var activePlayer: media._players.length > 0 ? media._players[0] : null
    readonly property int activePlayerIndex: media._stable.indexOf(media.activePlayer)
    function playerCount(): int {
        return media.usableCount;
    }
    function playerIndex(): int {
        return media.activePlayerIndex;
    }
    function cyclePlayer(): void {
        const stable = media._stable;
        if (stable.length < 2)
            return;
        const next = stable[(stable.indexOf(media.activePlayer) + 1) % stable.length];
        if (next)
            media.preferredPlayer = next.dbusName ?? next.identity ?? "";
    }
    function transport(fn: string, target): bool {
        const player = target ?? media.activePlayer;
        if (!player)
            return false;
        if (fn === "togglePlaying" && player.canTogglePlaying === false)
            return false;
        if (fn === "next" && player.canGoNext === false)
            return false;
        if (fn === "previous" && player.canGoPrevious === false)
            return false;
        if (typeof player[fn] !== "function")
            return false;
        try {
            player[fn]();
        } catch (_) {
            return false;
        }
        return true;
    }
    function mediaToggle(target): void {
        media.transport("togglePlaying", target);
    }
    function mediaNext(target): void {
        media.transport("next", target);
    }
    function mediaPrev(target): void {
        media.transport("previous", target);
    }
    property int pendingBrightness: -1
    function setBrightness(pct: real, quiet: bool): void {
        const clamped = Math.round(Theme.clamp(pct, Theme.brightnessMin, 100));
        media.brightness = clamped;
        media.brightnessPollEnabled = true;
        media.brightnessFailures = 0;
        media.pendingBrightness = clamped;
        brightnessApply.restart();
        brightnessConfirm.stop();
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
            brightnessConfirm.restart();
        }
    }
    Timer {
        id: brightnessConfirm
        interval: 350
        repeat: false
        onTriggered: {
            if (!brightnessProbe.running)
                brightnessProbe.running = true;
        }
    }
    function brightnessUp(): void {
        media.setBrightness(media.brightness + Theme.brightnessStep, false);
    }
    function brightnessDown(): void {
        media.setBrightness(media.brightness - Theme.brightnessStep, false);
    }
    function markBrightnessUnavailable(): void {
        media.brightnessAvailable = false;
        media.brightnessPollEnabled = false;
        media.brightnessFailures += 1;
    }
    Timer {
        id: brightnessPoll
        interval: 30000
        running: media.brightnessAvailable && media.brightnessPollEnabled
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            if (!brightnessProbe.running)
                brightnessProbe.running = true;
        }
    }
    Timer {
        id: brightnessRetry
        interval: 60000
        running: !media.brightnessAvailable && media.brightnessFailures < 3
        repeat: true
        onTriggered: {
            if (!brightnessProbe.running)
                brightnessProbe.running = true;
        }
    }
    Component.onCompleted: {
        if (!brightnessProbe.running)
            brightnessProbe.running = true;
    }
    Process {
        id: brightnessProbe
        command: ["brightnessctl", "-m"]
        onRunningChanged: {
            if (brightnessProbe.running)
                brightnessTimeout.restart();
            else
                brightnessTimeout.stop();
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (media.pendingBrightness >= 0)
                    return;
                const lines = String(text ?? "").split("\n").map(l => l.trim()).filter(l => l !== "");
                const line = lines.find(l => l.includes(",backlight,")) ?? lines[0] ?? "";
                const fields = line.split(",");
                if (fields.length >= 4) {
                    const pct = parseFloat(fields[3]);
                    if (!isNaN(pct)) {
                        media.brightness = pct;
                        media.brightnessAvailable = true;
                        media.brightnessPollEnabled = true;
                        media.brightnessFailures = 0;
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
    Timer {
        id: brightnessTimeout
        interval: 10000
        repeat: false
        onTriggered: {
            if (brightnessProbe.running) {
                brightnessProbe.running = false;
                media.markBrightnessUnavailable();
            }
        }
    }
}
