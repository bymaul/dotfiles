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

    // Second gate for fullscreen modal states (area picker): same
    // queue-then-flush behavior as suppressToasts, but independent
    // so two owners never fight over one flag.
    property bool suspended: false

    function flushPending(): void {
        const room = Math.max(0, 5 - notifs.toasts.length);

        notifs.toasts = [...notifs.pending.slice(0, room), ...notifs.toasts];
        notifs.pending = [];
        notifs.readCount = notifs.history.length;
    }

    // Snapshots keep the live object for action buttons, including
    // DND-suppressed ones (tracked, just never popped).
    property var history: []

    property int readCount: 0
    readonly property int unread: Math.max(0, history.length - readCount)

    // Monotonic id per shown toast. ToastCard delegates may hold a
    // copy of the model object (identity then fails), but copied
    // values still match, so dismissal keys on this, never on ===.
    property int toastSeq: 0

    function toastKey(t): var {
        return t && t.qsToastId !== undefined ? t.qsToastId : t;
    }

    function hideToast(n): void {
        const k = notifs.toastKey(n);

        notifs.toasts = notifs.toasts.filter(t => notifs.toastKey(t) !== k);
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

    // Shared entry for D-Bus notifications and internal toasts
    // (see notify). Works on the common shape: appName, summary,
    // body, urgency, hints, actions, image, appIcon, expireTimeout,
    // plus dismiss() and closed.connect().
    function handleNotification(notification): void {
        const syncId = notification.hints ? notification.hints["x-canonical-private-synchronous"] : undefined;

        if (syncId !== undefined) {
            for (const old of notifs.toasts) {
                const oldId = old.hints ? old.hints["x-canonical-private-synchronous"] : undefined;

                if (oldId === syncId) {
                    // hideToast first: internal toasts have no live
                    // object, so dismiss() alone would leave them up.
                    notifs.hideToast(old);
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

        notification.tracked = true;
        notification.closed.connect(() => {
            notifs.toasts = notifs.toasts.filter(t => t !== notification);
            notifs.pending = notifs.pending.filter(t => t !== notification);
        });

        // DND drops popups, except our own feedback, which must
        // confirm: mode toggles both directions, screenshots with
        // their Open/Copy actions. The snapshot above still lands
        // in the center either way.
        if (Modes.dndActive && notification.appName !== "dnd" && notification.appName !== "caffeine" && notification.appName !== "screenshot") {
            return;
        }

        if (notifs.suppressToasts || notifs.suspended) {
            if (syncId === undefined || notification.actions.length > 0) {
                notifs.pending = [notification, ...notifs.pending].slice(0, 5);
            }

            return;
        }

        const next = [notification, ...notifs.toasts].slice(0, 5);
        const dropped = notifs.toasts.filter(t => !next.includes(t));

        notification.qsToastId = ++notifs.toastSeq;
        notifs.toasts = next;

        for (const old of dropped) {
            old.dismiss();
            notifs.forgetLive(old);
        }
    }

    // Internal toast without a D-Bus round trip. Same pipeline as
    // notify-send (sync replace, history policy, DND, expiry), so
    // OSDs no longer fork an external binary to talk to ourselves.
    // opts: app, summary, body, icon, value (progress 0-100),
    // syncId, timeout (ms), urgency, filepath, actions ([{identifier, text}]).
    function notify(opts): void {
        const o = opts ?? {};
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
            expireTimeout: o.timeout ?? 5000,
            tracked: false,
            dismiss: () => {},
            closed: {
                connect: () => {}
            }
        });
    }
}
