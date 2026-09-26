pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
Singleton {
    id: notifs
    property var toasts: []
    property var pending: []
    property bool suppressToasts: false
    property var history: []
    property int readCount: 0
    readonly property int unread: Math.max(0, history.length - readCount)
    property int toastSeq: 0
    readonly property string historyFile: {
        const xdg = Quickshell.env("XDG_DATA_HOME") ?? "";
        const base = xdg !== "" ? xdg : (Quickshell.env("HOME") ?? "") + "/.local/share";
        return base + "/quickshell/notif-history.json";
    }
    function syncIdOf(n): var {
        return n?.hints ? n.hints["x-canonical-private-synchronous"] : undefined;
    }
    function isOwnFeedback(app: string): bool {
        if (app === "dnd" || app === "caffeine" || app === "bluelight" || app === "screenshot")
            return true;
        return app === "volume" || app === "brightness" || app === "media" || app === "power" || app === "emoji" || app === "clipboard" || app === "settings";
    }
    function isOsd(n): bool {
        if (!n || n.qsInternal !== true)
            return false;
        const k = n.qsSyncKey;
        return k === "volume" || k === "brightness" || k === "mic" || k === "media" || k === "charger" || k === "caffeine" || k === "dnd";
    }
    function bypassesDnd(n): bool {
        if (n?.qsInternal === true)
            return true;
        if (notifs.isOwnFeedback(n?.appName ?? ""))
            return true;
        return n?.urgency === NotificationUrgency.Critical;
    }
    function toastKey(t): var {
        return t && t.qsToastId !== undefined ? t.qsToastId : t;
    }
    function hideToast(n): void {
        if (!n) {
            console.warn("quickshell: hideToast called without notification");
            return;
        }
        const k = notifs.toastKey(n);
        notifs.toasts = notifs.toasts.filter(t => t !== n && notifs.toastKey(t) !== k);
    }
    function dismissToast(n): void {
        if (!n)
            return;
        notifs.hideToast(n);
        notifs.releaseHistoryLive(n);
        notifs.safeDismiss(n);
    }
    function consumeToast(n): void {
        if (!n)
            return;
        notifs.hideToast(n);
        notifs.safeDismiss(n);
        notifs.forgetLive(n);
    }
    function shelveToasts(): void {
        if (notifs.toasts.length === 0)
            return;
        notifs.pending = [...notifs.toasts, ...notifs.pending].slice(0, Theme.toastMax);
        notifs.toasts = [];
    }
    function flushPending(): void {
        const room = Math.max(0, Theme.toastMax - notifs.toasts.length);
        const restored = notifs.pending.slice(0, room);
        for (const t of restored)
            notifs.stampToast(t);
        notifs.toasts = [...restored, ...notifs.toasts];
        notifs.pending = notifs.pending.slice(room);
        notifs.readCount = notifs.history.length;
    }
    function stampToast(n): void {
        if (!n)
            return;
        try {
            n.addedAt = Date.now();
        } catch (_) {}
    }
    function sweepExpired(): void {
        const now = Date.now();
        for (const t of notifs.toasts) {
            const exp = t ? t.expireTimeout : undefined;
            if (!(exp > 0))
                continue;
            const age = now - (t.addedAt ?? now);
            if (age > exp + 2000)
                notifs.hideToast(t);
        }
    }
    function safeDismiss(n): void {
        if (!n)
            return;
        try {
            n.dismiss();
        } catch (_) {}
        notifs.detachClosed(n);
    }
    function detachClosed(n): void {
        if (!n || !n._qsOnClosed)
            return;
        try {
            n.closed.disconnect(n._qsOnClosed);
        } catch (_) {}
        n._qsOnClosed = null;
    }
    function releaseHistoryLive(n): void {
        if (!n)
            return;
        let changed = false;
        for (const h of notifs.history) {
            if (h && h.live === n) {
                h.live = null;
                changed = true;
            }
        }
        if (changed) {
            notifs.history = notifs.history.slice();
            notifs.schedulePersist();
        }
    }
    function trackClosed(n): void {
        if (!n || n._qsOnClosed)
            return;
        try {
            n._qsOnClosed = function () {
                notifs.toasts = notifs.toasts.filter(t => t !== n);
                notifs.pending = notifs.pending.filter(t => t !== n);
                notifs.releaseHistoryLive(n);
                notifs.detachClosed(n);
            };
            n.closed.connect(n._qsOnClosed);
        } catch (_) {
            n._qsOnClosed = null;
        }
    }
    function dropLive(item): void {
        if (!item || !item.live)
            return;
        const n = item.live;
        item.live = null;
        notifs.safeDismiss(n);
    }
    function forgetLive(n): void {
        notifs.detachClosed(n);
        notifs.history = notifs.history.filter(h => h.live !== n);
        notifs.pending = notifs.pending.filter(t => t !== n);
        notifs.readCount = Math.min(notifs.readCount, notifs.history.length);
        notifs.schedulePersist();
    }
    function filepathOf(notification): string {
        const hints = notification?.hints;
        return hints && typeof hints["filepath"] === "string" ? hints["filepath"] : "";
    }
    function activateAction(notification, action): bool {
        if (!notification || !action)
            return false;
        const path = notifs.filepathOf(notification);
        const id = action?.identifier ?? "";
        if (path !== "" && (id === "open" || id === "path" || id === "default")) {
            if (id === "path")
                Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "qs", path]);
            else
                Quickshell.execDetached(["xdg-open", path]);
            return true;
        }
        try {
            action.invoke();
        } catch (_) {
            return false;
        }
        return true;
    }
    function defaultActionOf(actions): var {
        const list = actions ?? [];
        if (list.length === 0)
            return null;
        return list.find(a => a.identifier === "default") ?? list[0] ?? null;
    }
    function activateDefault(live): bool {
        if (!live)
            return false;
        const act = notifs.defaultActionOf(live?.actions ?? []);
        if (!act)
            return false;
        return notifs.activateAction(live, act);
    }
    function clearHistory(): void {
        for (const h of notifs.history)
            notifs.dropLive(h);
        notifs.history = [];
        notifs.readCount = 0;
        notifs.schedulePersist();
    }
    function dismissHistoryAt(i: int): void {
        if (i < 0 || i >= notifs.history.length)
            return;
        notifs.dropLive(notifs.history[i]);
        notifs.history = notifs.history.filter((_, idx) => idx !== i);
        notifs.readCount = Math.min(notifs.readCount, notifs.history.length);
        notifs.schedulePersist();
    }
    function snapshot(n): var {
        const cands = [n.image, n.appIcon];
        const hit = cands.find(s => typeof s === "string" && s !== "");
        return {
            app: n.appName ?? "",
            summary: n.summary ?? "",
            body: n.body ?? "",
            icon: hit ?? "",
            critical: n.urgency === NotificationUrgency.Critical,
            time: new Date(),
            syncId: notifs.syncIdOf(n),
            live: n
        };
    }
    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        onNotification: notification => notifs.handleNotification(notification)
    }
    function handleNotification(notification): void {
        const syncId = notifs.syncIdOf(notification);
        if (syncId !== undefined) {
            for (const old of notifs.toasts) {
                if (notifs.syncIdOf(old) === syncId) {
                    notifs.hideToast(old);
                    notifs.safeDismiss(old);
                    notifs.forgetLive(old);
                }
            }
        }
        if ((syncId === undefined || (notification.actions ?? []).length > 0) && notification.transient !== true) {
            let next = [notifs.snapshot(notification), ...notifs.history];
            if (syncId !== undefined)
                next = [next[0], ...next.slice(1).filter(h => h.syncId !== syncId)];
            for (const h of next.slice(Theme.historyMax))
                notifs.dropLive(h);
            notifs.history = next.slice(0, Theme.historyMax);
            notifs.schedulePersist();
        }
        notification.tracked = true;
        notifs.trackClosed(notification);
        notifs.stampToast(notification);
        if (Modes.dndActive && !notifs.bypassesDnd(notification))
            return;
        if (notifs.suppressToasts) {
            if (syncId === undefined || (notification.actions ?? []).length > 0)
                notifs.pending = [notification, ...notifs.pending].slice(0, Theme.toastMax);
            return;
        }
        let next = [notification, ...notifs.toasts].slice(0, Theme.toastMax);
        if (notifs.isOsd(notification))
            next = [next[0], ...next.slice(1).filter(t => !notifs.isOsd(t))];
        // Evicted toasts stay tracked so their history entries keep working
        // actions; the closed handler cleans up when the sender withdraws.
        notification.qsToastId = ++notifs.toastSeq;
        notifs.toasts = next;
    }
    function notify(opts): void {
        const o = opts ?? {};
        if (o.syncId !== undefined && !(Modes.dndActive && !notifs.isOwnFeedback(o.app ?? ""))) {
            const cur = notifs.toasts.find(t => t && t.qsInternal === true && t.qsSyncKey === o.syncId);
            if (cur) {
                cur.appName = o.app ?? cur.appName;
                cur.summary = o.summary ?? "";
                cur.body = o.body ?? "";
                cur.urgency = o.urgency ?? NotificationUrgency.Normal;
                cur.appIcon = o.icon ?? "";
                cur.expireTimeout = o.timeout ?? Theme.toastTimeout;
                notifs.stampToast(cur);
                cur.hints = {};
                if (o.hints !== undefined)
                    for (const hk in o.hints)
                        cur.hints[hk] = o.hints[hk];
                if (o.value !== undefined)
                    cur.hints["value"] = o.value;
                cur.hints["x-canonical-private-synchronous"] = o.syncId;
                if (o.filepath !== undefined)
                    cur.hints["filepath"] = o.filepath;
                notifs.toastSeq += 1;
                notifs.toasts = notifs.toasts.slice();
                return;
            }
        }
        const hints = {};
        if (o.hints !== undefined)
            for (const hk in o.hints)
                hints[hk] = o.hints[hk];
        if (o.value !== undefined)
            hints["value"] = o.value;
        if (o.syncId !== undefined)
            hints["x-canonical-private-synchronous"] = o.syncId;
        if (o.filepath !== undefined)
            hints["filepath"] = o.filepath;
        notifs.handleNotification({
            appName: o.app ?? "",
            summary: o.summary ?? "",
            body: o.body ?? "",
            urgency: o.urgency ?? NotificationUrgency.Normal,
            transient: false,
            resident: false,
            hints: hints,
            actions: o.actions ?? [],
            image: "",
            appIcon: o.icon ?? "",
            expireTimeout: o.timeout ?? Theme.toastTimeout,
            qsInternal: true,
            qsSyncKey: o.syncId,
            tracked: false,
            dismiss: () => {},
            closed: {
                connect: () => {},
                disconnect: () => {}
            }
        });
    }
    function schedulePersist(): void {
        persistTimer.restart();
    }
    function persistHistory(): void {
        if (saver.running) {
            persistTimer.restart();
            return;
        }
        const data = notifs.history.slice(0, Theme.historyMax).map(h => ({
                    app: h?.app ?? "",
                    summary: h?.summary ?? "",
                    body: h?.body ?? "",
                    icon: h?.icon ?? "",
                    critical: !!h?.critical,
                    time: h?.time instanceof Date ? h.time.getTime() : Date.now(),
                    syncId: h?.syncId ?? null
                }));
        saver.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")"; printf "%s\\n" "$1" > "$2.tmp"; mv -f "$2.tmp" "$2"', "qs", JSON.stringify(data), notifs.historyFile];
        saver.running = true;
    }
    Timer {
        id: persistTimer
        interval: 1000
        repeat: false
        onTriggered: notifs.persistHistory()
    }
    Timer {
        id: expirySweep
        interval: 10000
        repeat: true
        running: notifs.toasts.length > 0
        onTriggered: notifs.sweepExpired()
    }
    Process {
        id: saver
    }
    Process {
        id: historyLoader
        command: ["cat", notifs.historyFile]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text);
                    if (!Array.isArray(arr))
                        return;
                    const restored = arr.slice(0, Theme.historyMax).map(e => ({
                                app: String(e?.app ?? ""),
                                summary: String(e?.summary ?? ""),
                                body: String(e?.body ?? ""),
                                icon: String(e?.icon ?? ""),
                                critical: !!e?.critical,
                                time: new Date(typeof e?.time === "number" ? e.time : Date.now()),
                                syncId: e?.syncId ?? undefined,
                                live: null
                            }));
                    notifs.history = [...notifs.history, ...restored].slice(0, Theme.historyMax);
                    notifs.readCount = notifs.history.length;
                } catch (_) {}
            }
        }
        Component.onCompleted: historyLoader.running = true
    }
}
