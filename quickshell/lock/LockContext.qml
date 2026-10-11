import QtQuick
import Quickshell
import Quickshell.Io
import "../services/SettingsUtil.js" as U
import Quickshell.Services.Pam
Scope {
    id: root
    signal unlocked()
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property string authMessage: ""
    property int failedAttempts: 0
    property int shownSurfaces: 0
    readonly property bool lockShown: root.shownSurfaces > 0
    function surfaceShown(on: bool): void {
        if (on)
            root.shownSurfaces += 1;
        else if (root.shownSurfaces > 0)
            root.shownSurfaces -= 1;
    }
    property int lockoutSecsLeft: 0
    property bool rateLimited: false
    property bool waitAfterFailure: false
    property string faillockInfo: ""
    property bool faillockLocked: false
    property double faillockLatest: 0
    property int faillockUnlockMs: 600000
    property bool faillockWarnMuted: false
    readonly property string loginUser: (Quickshell.env("USER") ?? Quickshell.env("LOGNAME") ?? "")
    onLockShownChanged: {
        if (root.lockShown) {
            root.faillockWarnMuted = false;
            root.refreshFaillock();
        } else {
            root.faillockInfo = "";
            root.faillockLocked = false;
            root.faillockWarnMuted = false;
            root.faillockLatest = 0;
            root.faillockUnlockMs = 600000;
        }
    }
    function refreshFaillock(): void {
        if (root.loginUser === "" || failProbe.running)
            return;
        failProbe.running = true;
    }
    readonly property string statusText: {
        if (root.faillockLocked && root.faillockInfo !== "")
            return root.faillockInfo;
        if (root.rateLimited && root.authMessage !== "")
            return root.authMessage;
        if (root.authMessage !== "")
            return root.authMessage;
        if (root.showFailure)
            return "Incorrect password, try again";
        return root.faillockInfo;
    }
    readonly property string statusKind: {
        if (root.faillockLocked)
            return "danger";
        if (root.rateLimited)
            return "info";
        if (root.authMessage !== "")
            return "warn";
        if (root.showFailure)
            return "danger";
        return "info";
    }
    function parseFaillock(text: string): void {
        root.faillockInfo = "";
        root.faillockLocked = false;
        if (typeof text !== "string" || text === "" || text.length > 65536)
            return;
        let deny = 3, unlockTime = 600;
        let inTally = false, valid = 0, latest = 0;
        for (const raw of text.split("\n").slice(-100)) {
            const line = raw.trim();
            if (line === "---TALLY---") {
                inTally = true;
                continue;
            }
            if (!inTally) {
                const m = line.match(/^(deny|unlock_time)\s*=\s*(\d+)/);
                if (m) {
                    const v = parseInt(m[2], 10);
                    if (m[1] === "deny")
                        deny = Math.max(1, Math.min(100, v));
                    else
                        unlockTime = Math.max(0, Math.min(86400, v));
                }
                continue;
            }
            const t = line.match(/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})\s+\S+\s+\S+\s+(V?)\s*$/);
            if (!t || t[7] !== "V")
                continue;
            const ts = new Date(parseInt(t[1], 10), parseInt(t[2], 10) - 1, parseInt(t[3], 10), parseInt(t[4], 10), parseInt(t[5], 10), parseInt(t[6], 10)).getTime();
            if (isNaN(ts))
                continue;
            valid += 1;
            if (ts > latest)
                latest = ts;
        }
        if (valid <= 0)
            return;
        const now = Date.now();
        if (valid >= deny && now - latest < unlockTime * 1000) {
            root.faillockLocked = true;
            root.faillockLatest = latest;
            root.faillockUnlockMs = unlockTime * 1000;
            root.faillockInfo = root.lockedCountdown(unlockTime * 1000 - (now - latest));
        } else if (!root.faillockWarnMuted) {
            root.faillockInfo = valid + " failed login" + (valid === 1 ? "" : "s") + " — account locks after " + deny;
        }
    }
    function lockedCountdown(leftMs: real): string {
        return "Account locked — " + U.fmtTimeout(Math.max(1, Math.ceil(leftMs / 1000))) + " left";
    }
    function showWaitMessage(wrong: bool): void {
        root.showFailure = false;
        root.rateLimited = true;
        root.waitAfterFailure = wrong;
        root.authMessage = (wrong ? "Incorrect password — " : "Too many attempts — ") + "try again in " + Math.max(1, root.lockoutSecsLeft) + "s";
    }
    onCurrentTextChanged: {
        showFailure = false;
        if (lockout.running) {
            root.showWaitMessage(false);
        } else {
            root.rateLimited = false;
            root.waitAfterFailure = false;
            authMessage = "";
        }
    }
    function tryUnlock(): void {
        if (currentText === "" || unlockInProgress)
            return;
        if (root.faillockLocked)
            return;
        if (lockout.running) {
            root.showWaitMessage(false);
            return;
        }
        root.rateLimited = false;
        root.waitAfterFailure = false;
        unlockInProgress = true;
        try {
            pam.start();
        } catch (_) {
            unlockInProgress = false;
            root.showFailure = false;
            root.authMessage = "Authentication unavailable — try again";
            return;
        }
        pamWatchdog.restart();
    }
    Timer {
        id: lockout
        interval: 1000
        repeat: false
    }
    Timer {
        id: countdownTick
        interval: 1000
        repeat: true
        running: root.rateLimited || (root.lockShown && root.faillockLocked)
        onTriggered: {
            if (root.rateLimited && !pam.active) {
                if (!lockout.running) {
                    root.rateLimited = false;
                    root.waitAfterFailure = false;
                    root.lockoutSecsLeft = 0;
                    root.authMessage = "";
                } else {
                    if (root.lockoutSecsLeft > 0)
                        root.lockoutSecsLeft -= 1;
                    root.showWaitMessage(root.waitAfterFailure);
                }
            }
            if (root.lockShown && root.faillockLocked) {
                const left = root.faillockUnlockMs - (Date.now() - root.faillockLatest);
                if (left <= 0) {
                    root.faillockLocked = false;
                    root.faillockWarnMuted = true;
                    root.faillockInfo = "";
                    root.refreshFaillock();
                } else {
                    root.faillockInfo = root.lockedCountdown(left);
                }
            }
        }
    }
    Timer {
        id: pamWatchdog
        interval: 15000
        repeat: false
        onTriggered: {
            if (root.unlockInProgress) {
                if (pam.active) {
                    try {
                        pam.abort();
                    } catch (_) {}
                }
                root.unlockInProgress = false;
                root.currentText = "";
                root.showFailure = false;
                root.authMessage = "Authentication timed out — try again";
            }
        }
    }
    Timer {
        id: failPoll
        interval: 15000
        repeat: true
        running: root.lockShown && root.loginUser !== "" && (root.faillockLocked || root.faillockInfo !== "")
        onTriggered: root.refreshFaillock()
    }
    Process {
        id: failProbe
        command: ["sh", "-c", 'grep -v "^[[:space:]]*#" /etc/security/faillock.conf 2>/dev/null; printf "\\n---TALLY---\\n"; command -v faillock >/dev/null 2>&1 && faillock --user "$1" 2>/dev/null || echo NOFAILLOCK', "qs", root.loginUser]
        stdout: StdioCollector {
            onStreamFinished: root.parseFaillock(text)
        }
    }
    function lockoutDelayMs(): int {
        // Gentle backoff after 5 failures: 1s, 2s, 4s, then 8s.
        const step = Math.max(0, root.failedAttempts - 5);
        const ms = 1000 * Math.pow(2, Math.min(step, 3));
        return Math.min(8000, Math.round(ms));
    }
    function armLockout(): void {
        lockout.interval = root.lockoutDelayMs();
        lockout.restart();
        root.lockoutSecsLeft = Math.max(1, Math.ceil(lockout.interval / 1000));
    }
    function clearAuth(): void {
        pamWatchdog.stop();
        currentText = "";
        showFailure = false;
        authMessage = "";
        unlockInProgress = false;
        rateLimited = false;
        waitAfterFailure = false;
        lockoutSecsLeft = 0;
        faillockInfo = "";
        faillockLocked = false;
        faillockLatest = 0;
        faillockUnlockMs = 600000;
        faillockWarnMuted = false;
    }
    function reset(): void {
        if (pam.active) {
            try {
                pam.abort();
            } catch (_) {}
        }
        root.clearAuth();
    }
    PamContext {
        id: pam
        onPamMessage: {
            if (responseRequired) {
                try {
                    respond(root.currentText);
                } catch (_) {
                    pamWatchdog.stop();
                    root.unlockInProgress = false;
                    root.showFailure = false;
                    root.authMessage = "Authentication unavailable — try again";
                }
            } else if (messageIsError) {
                root.authMessage = message;
            }
        }
        onError: error => {
            pamWatchdog.stop();
            root.currentText = "";
            root.authMessage = "Auth error: " + error;
            root.unlockInProgress = false;
        }
        onCompleted: result => {
            pamWatchdog.stop();
            if (result === PamResult.Success) {
                root.failedAttempts = 0;
                lockout.stop();
                root.clearAuth();
                root.unlocked();
                return;
            }
            root.failedAttempts += 1;
            // Always pace with our own backoff past 5 failures, but let PAM's
            // own message (e.g. faillock "account is locked") win the display:
            // the system message explains the real cause.
            const pamSaid = root.authMessage !== "";
            if (root.failedAttempts >= 5)
                root.armLockout();
            root.currentText = "";
            if (!pamSaid && root.failedAttempts >= 5)
                root.showWaitMessage(true);
            else
                root.showFailure = true;
            root.unlockInProgress = false;
            root.faillockWarnMuted = false;
            root.refreshFaillock();
        }
    }
}
