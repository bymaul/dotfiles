pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: jack
    property bool plugged: false
    property bool hasJack: false
    property bool jackReady: false
    property string activePort: ""
    property string sinkName: ""
    function jackToast(isPlugged: bool): void {
        if (isPlugged)
            Notifs.notify({app: "volume", summary: "Headphones", body: "Jack plugged in", icon: "audio-headphones-symbolic", syncId: "headphones", timeout: Theme.osdTimeout});
        else
            Notifs.notify({app: "volume", summary: "Speakers", body: "Jack unplugged", icon: "audio-speakers-symbolic", syncId: "headphones", timeout: Theme.osdTimeout});
    }
    function applySinks(text): void {
        const blocks = String(text ?? "").split("Sink #");
        let found = false;
        let port = "";
        let name = "";
        let isPlugged = false;
        for (let i = 1; i < blocks.length; i++) {
            const b = blocks[i];
            if (b.toLowerCase().indexOf("headphone") === -1)
                continue;
            const pm = b.match(/Active Port:\s*(\S+)/);
            if (!pm)
                continue;
            const nm = b.match(/Name:\s*(\S+)/);
            found = true;
            port = pm[1].trim();
            name = nm ? nm[1].trim() : "";
            const pl = port.toLowerCase();
            isPlugged = pl.indexOf("headphone") !== -1 || pl.indexOf("headset") !== -1;
            break;
        }
        if (!found) {
            jack.hasJack = false;
            return;
        }
        jack.hasJack = true;
        jack.activePort = port;
        jack.sinkName = name;
        if (!jack.jackReady) {
            jack.plugged = isPlugged;
            return;
        }
        if (isPlugged === jack.plugged)
            return;
        jack.plugged = isPlugged;
        jack.jackToast(isPlugged);
    }
    function requestQuery(): void {
        if (queryProc.running) {
            queryDebounce.restart();
            return;
        }
        queryProc.running = true;
    }
    function maybeArm(): void {
        if (!jack.jackReady && !jackGrace.running)
            jackGrace.restart();
    }
    Timer {
        id: jackGrace
        interval: 2000
        repeat: false
        onTriggered: jack.jackReady = true
    }
    Timer {
        id: queryDebounce
        interval: 300
        repeat: false
        onTriggered: jack.requestQuery()
    }
    Timer {
        id: pollFallback
        interval: 10000
        running: true
        repeat: true
        onTriggered: jack.requestQuery()
    }
    Timer {
        id: subscribeRetry
        interval: 5000
        repeat: false
        onTriggered: {
            if (!subscribeProc.running)
                subscribeProc.running = true;
        }
    }
    Process {
        id: queryProc
        command: ["pactl", "list", "sinks"]
        stdout: StdioCollector {
            onStreamFinished: jack.applySinks(text)
        }
    }
    Process {
        id: subscribeProc
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: data => {
                const s = String(data ?? "").toLowerCase();
                if (s.indexOf("sink") !== -1 || s.indexOf("card") !== -1)
                    queryDebounce.restart();
            }
        }
        onExited: (exitCode, exitStatus) => {
            subscribeRetry.restart();
        }
    }
    Component.onCompleted: {
        console.warn("quickshell: AudioJack singleton instantiated");
        jack.maybeArm();
        subscribeProc.running = true;
        jack.requestQuery();
    }
}
