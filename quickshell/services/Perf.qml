pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: perf
    property int cpuUsage: 0
    property real memUsed: 0
    property real cpuTotal: 0
    property real cpuIdle: 0
    function parseStat(text: string): void {
        const line = String(text ?? "").split("\n").find(l => l.startsWith("cpu "));
        if (!line)
            return;
        const nums = line.trim().split(/\s+/);
        if (nums.length < 6 || nums[0] !== "cpu")
            return;
        let total = 0;
        for (let i = 1; i < nums.length; i++) {
            const v = parseInt(nums[i]);
            if (isNaN(v))
                return;
            total += v;
        }
        const idleUser = parseInt(nums[4]);
        const idleNice = parseInt(nums[5]);
        if (isNaN(idleUser) || isNaN(idleNice))
            return;
        const idle = idleUser + idleNice;
        if (perf.cpuTotal > 0) {
            const dTotal = total - perf.cpuTotal;
            const dIdle = idle - perf.cpuIdle;
            if (dTotal > 0)
                perf.cpuUsage = Math.round((dTotal - dIdle) / dTotal * 100);
        }
        perf.cpuTotal = total;
        perf.cpuIdle = idle;
    }
    function parseMem(text: string): void {
        const totalMatch = text.match(/MemTotal:\s+(\d+)/);
        const availMatch = text.match(/MemAvailable:\s+(\d+)/);
        if (totalMatch && availMatch) {
            const totalKb = parseInt(totalMatch[1]);
            const availKb = parseInt(availMatch[1]);
            if (isNaN(totalKb) || isNaN(availKb))
                return;
            perf.memUsed = (totalKb - availKb) / 1024 / 1024;
        }
    }
    Timer {
        id: poller
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statView.reload();
            memView.reload();
        }
    }
    FileView {
        id: statView
        path: "/proc/stat"
        printErrors: false
        onLoaded: perf.parseStat(statView.text())
        onLoadFailed: {}
    }
    FileView {
        id: memView
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: perf.parseMem(memView.text())
        onLoadFailed: {}
    }
}
