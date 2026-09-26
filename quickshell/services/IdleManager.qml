pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Generates and atomically writes hypridle.conf, then restarts hypridle.
// Pure: all inputs passed as arguments, no dependency on Settings.
Singleton {
    id: idle

    property bool dirty: false
    property int dimTimeout: 0
    property int lockTimeout: 0
    property int screenOffTimeout: 0
    property int suspendTimeout: 0
    property string targetFile: ""

    function request(dim: int, lock: int, screenOff: int, suspend: int, file: string): void {
        idle.dimTimeout = dim;
        idle.lockTimeout = lock;
        idle.screenOffTimeout = screenOff;
        idle.suspendTimeout = suspend;
        idle.targetFile = file;
        debounce.restart();
    }
    function render(): string {
        const L = [];
        L.push("general {");
        L.push("    lock_cmd = qs ipc call bar lock");
        L.push("    before_sleep_cmd = loginctl lock-session");
        L.push("    after_sleep_cmd = hyprctl eval 'hl.dispatch(hl.dsp.dpms(\"on\"))'");
        L.push("}");
        L.push("");
        if (idle.dimTimeout > 0) {
            L.push("listener {");
            L.push("    timeout = " + idle.dimTimeout);
            L.push("    on-timeout = [ \"$(brightnessctl g)\" -gt 2500 ] && brightnessctl -s set 3%; hyprctl hyprsunset gamma 50");
            L.push("    on-resume = brightnessctl -r; hyprctl hyprsunset gamma 100");
            L.push("}");
            L.push("");
            L.push("listener {");
            L.push("    timeout = " + idle.dimTimeout);
            L.push("    on-timeout = brightnessctl -sd '*:kbd_backlight' set 0");
            L.push("    on-resume = brightnessctl -rd '*:kbd_backlight'");
            L.push("}");
            L.push("");
        }
        if (idle.lockTimeout > 0) {
            L.push("listener {");
            L.push("    timeout = " + idle.lockTimeout);
            L.push("    on-timeout = loginctl lock-session");
            L.push("}");
            L.push("");
        }
        if (idle.screenOffTimeout > 0) {
            L.push("listener {");
            L.push("    timeout = " + idle.screenOffTimeout);
            L.push("    on-timeout = hyprctl eval 'hl.dispatch(hl.dsp.dpms(\"off\"))'");
            L.push("    on-resume = hyprctl eval 'hl.dispatch(hl.dsp.dpms(\"on\"))'");
            L.push("}");
            L.push("");
        }
        if (idle.suspendTimeout > 0) {
            L.push("listener {");
            L.push("    timeout = " + idle.suspendTimeout);
            L.push("    on-timeout = systemctl suspend");
            L.push("}");
            L.push("");
        }
        return L.join("\n");
    }
    function writeNow(): void {
        if (writer.running) {
            idle.dirty = true;
            return;
        }
        writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")"; printf "%s\\n" "$2" > "$1.tmp"; mv -f "$1.tmp" "$1"', "qs", idle.targetFile, idle.render()];
        writer.running = true;
    }
    Timer {
        id: debounce
        interval: 500
        repeat: false
        onTriggered: idle.writeNow()
    }
    Process {
        id: writer
        onExited: exitCode => {
            if (idle.dirty) {
                idle.dirty = false;
                idle.writeNow();
                return;
            }
            if (exitCode !== 0) {
                Notifs.notify({app: "settings", summary: "Idle config write failed", body: idle.targetFile, timeout: 5000});
                return;
            }
            restarter.running = true;
        }
    }
    Process {
        id: restarter
        command: ["sh", "-c", "pkill -x hypridle 2>/dev/null; sleep 0.2; command -v hypridle >/dev/null || exit 0; hypridle >/dev/null 2>&1 &"]
        onExited: exitCode => {
            if (exitCode !== 0)
                Notifs.notify({app: "settings", summary: "hypridle restart failed", body: "check hypridle.conf", timeout: 5000});
        }
    }
}
