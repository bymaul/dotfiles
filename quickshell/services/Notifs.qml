pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification server policy: DND suppresses popups; a timeout
// hides cards but live objects stay resident for history buttons.
Singleton {
    id: notifs

    property var toasts: []

    property var pending: []

    property bool suppressToasts: false

    function flushPending(): void {
        const room = Math.max(0, 5 - notifs.toasts.length);

        notifs.toasts = [...notifs.pending.slice(0, room), ...notifs.toasts];
        notifs.pending = [];
        notifs.readCount = notifs.history.length;
    }

    // Snapshots keep the live object for action buttons, except
    // DND-suppressed ones, which arrive already dead (live: null).
    property var history: []

    property int readCount: 0
    readonly property int unread: Math.max(0, history.length - readCount)

    function hideToast(n): void {
        notifs.toasts = notifs.toasts.filter(t => t !== n);
    }

    function hideAllToasts(): void {
        notifs.toasts = [];
    }

    function dropLive(item): void {
        if (!item || !item.live)
            return;

        // A dead sender's object can throw; never propagate.
        try {
            item.live.dismiss();
        } catch (_) {}
    }

    function forgetLive(n): void {
        notifs.history = notifs.history.filter(h => h.live !== n);
        notifs.pending = notifs.pending.filter(t => t !== n);
        notifs.readCount = Math.min(notifs.readCount, notifs.history.length);
    }

    function filepathOf(notification): string {
        const hints = notification?.hints;
        const path = hints && typeof hints["filepath"] === "string" ? hints["filepath"] : "";

        return path;
    }

    // File-backed notifications (screenshots): the sender is already
    // gone, so Open/Copy run here. Returns true when handled natively.
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
        for (const h of history)
            notifs.dropLive(h);

        history = [];
        readCount = 0;
    }

    function dismissHistoryAt(i: int): void {
        if (i < 0 || i >= history.length)
            return;
        notifs.dropLive(history[i]);
        history = history.filter((_, idx) => idx !== i);
        readCount = Math.min(readCount, history.length);
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
            syncId: n.hints ? n.hints["x-canonical-private-synchronous"] : undefined,
            live: Modes.dndActive ? null : n
        };
    }

    NotificationServer {
        id: server

        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true

        onNotification: notification => {
            const syncId = notification.hints ? notification.hints["x-canonical-private-synchronous"] : undefined;

            if (syncId !== undefined) {
                for (const old of notifs.toasts) {
                    const oldId = old.hints ? old.hints["x-canonical-private-synchronous"] : undefined;

                    if (oldId === syncId) {
                        old.dismiss();
                        notifs.forgetLive(old);
                    }
                }
            }

            // Actionable replacers (screenshots) are stored; pure
            // transient feedback (volume OSD) is shown, never stored.
            if (syncId === undefined || notification.actions.length > 0) {
                let next = [notifs.snapshot(notification), ...notifs.history];

                if (syncId !== undefined) {
                    for (const h of next.slice(1)) {
                        if (h.syncId === syncId)
                            notifs.dropLive(h);
                    }

                    next = [next[0], ...next.slice(1).filter(h => h.syncId !== syncId)];
                }

                for (const h of next.slice(30))
                    notifs.dropLive(h);

                notifs.history = next.slice(0, 30);
            }

            // DND drops popups, except our own mode toggles, which
            // must confirm both directions.
            if (Modes.dndActive && notification.appName !== "dnd" && notification.appName !== "caffeine") {
                notification.tracked = false;
                return;
            }

            notification.tracked = true;
            notification.closed.connect(() => {
                notifs.toasts = notifs.toasts.filter(t => t !== notification);
                notifs.pending = notifs.pending.filter(t => t !== notification);
            });

            if (notifs.suppressToasts) {
                if (syncId === undefined || notification.actions.length > 0) {
                    notifs.pending = [notification, ...notifs.pending].slice(0, 5);
                }

                return;
            }

            const next = [notification, ...notifs.toasts].slice(0, 5);
            const dropped = notifs.toasts.filter(t => !next.includes(t));

            notifs.toasts = next;

            for (const old of dropped) {
                old.dismiss();
                notifs.forgetLive(old);
            }
        }
    }
}
