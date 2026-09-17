pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../Palette.js" as Palette
Singleton {
    id: notifs
    property var toasts: []
    property var pending: []
    property bool suppressToasts: false
    property var history: []
    property int readCount: 0
    readonly property int unread: Math.max(0, history.length - readCount)
    property int toastSeq: 0
    function syncIdOf(n): var {
        return n?.hints ? n.hints["x-canonical-private-synchronous"] : undefined;
    }
    function isOwnFeedback(app: string): bool {
        return app === "dnd" || app === "caffeine" || app === "screenshot";
    }
    function toastKey(t): var {
        return t && t.qsToastId !== undefined ? t.qsToastId : t;
    }
    function hideToast(n): void {
        const k = notifs.toastKey(n);
        notifs.toasts = notifs.toasts.filter(t => notifs.toastKey(t) !== k);
    }
    function shelveToasts(): void {
        if (notifs.toasts.length === 0)
            return;
        notifs.pending = [...notifs.toasts, ...notifs.pending].slice(0, Palette.toastMax);
        notifs.toasts = [];
    }
    function flushPending(): void {
        const room = Math.max(0, Palette.toastMax - notifs.toasts.length);
        notifs.toasts = [...notifs.pending.slice(0, room), ...notifs.toasts];
        notifs.pending = notifs.pending.slice(room);
        notifs.readCount = notifs.history.length;
    }
    function safeDismiss(n): void {
        if (!n)
            return;
        try {
            n.dismiss();
        } catch (_) {}
    }
    function dropLive(item): void {
        if (!item || !item.live)
            return;
        notifs.safeDismiss(item.live);
    }
    function forgetLive(n): void {
        notifs.history = notifs.history.filter(h => h.live !== n);
        notifs.pending = notifs.pending.filter(t => t !== n);
        notifs.readCount = Math.min(notifs.readCount, notifs.history.length);
    }
    function filepathOf(notification): string {
        const hints = notification?.hints;
        return hints && typeof hints["filepath"] === "string" ? hints["filepath"] : "";
    }
    function activateAction(notification, action): bool {
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
        } catch (_) {}
        return false;
    }
    function clearHistory(): void {
        for (const h of notifs.history)
            notifs.dropLive(h);
        notifs.history = [];
        notifs.readCount = 0;
    }
    function dismissHistoryAt(i: int): void {
        if (i < 0 || i >= notifs.history.length)
            return;
        notifs.dropLive(notifs.history[i]);
        notifs.history = notifs.history.filter((_, idx) => idx !== i);
        notifs.readCount = Math.min(notifs.readCount, notifs.history.length);
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
        if (syncId === undefined || (notification.actions ?? []).length > 0) {
            let next = [notifs.snapshot(notification), ...notifs.history];
            if (syncId !== undefined)
                next = [next[0], ...next.slice(1).filter(h => h.syncId !== syncId)];
            for (const h of next.slice(Palette.historyMax))
                notifs.dropLive(h);
            notifs.history = next.slice(0, Palette.historyMax);
        }
        notification.tracked = true;
        notification.closed.connect(() => {
            notifs.toasts = notifs.toasts.filter(t => t !== notification);
            notifs.pending = notifs.pending.filter(t => t !== notification);
        });
        if (Modes.dndActive && !notifs.isOwnFeedback(notification.appName))
            return;
        if (notifs.suppressToasts) {
            if (syncId === undefined || (notification.actions ?? []).length > 0)
                notifs.pending = [notification, ...notifs.pending].slice(0, Palette.toastMax);
            return;
        }
        const next = [notification, ...notifs.toasts].slice(0, Palette.toastMax);
        const dropped = notifs.toasts.filter(t => !next.includes(t));
        notification.qsToastId = ++notifs.toastSeq;
        notifs.toasts = next;
        for (const old of dropped) {
            notifs.safeDismiss(old);
            notifs.forgetLive(old);
        }
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
                cur.expireTimeout = o.timeout ?? Palette.toastTimeout;
                cur.hints = {};
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
            hints: hints,
            actions: o.actions ?? [],
            image: "",
            appIcon: o.icon ?? "",
            expireTimeout: o.timeout ?? Palette.toastTimeout,
            qsInternal: true,
            qsSyncKey: o.syncId,
            tracked: false,
            dismiss: () => {},
            closed: {
                connect: () => {}
            }
        });
    }
}
