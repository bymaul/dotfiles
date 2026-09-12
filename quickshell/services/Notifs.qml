pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Desktop notification server (replaces mako). Toast UI lives in
// popups/ToastStack.qml; this singleton owns policy:
//
// - DND drops popups entirely (mako parity: invisible mode).
// - Same synchronous-id toasts replace their predecessor instead of
//   stacking (covers volume/brightness OSD spam).
// - At most 5 live toasts, newest first.
// - Toast timeout only HIDES the card: the server object stays
//   resident so history action buttons remain invokable. Objects
//   are released on history dismiss/clear/cap-eviction.
Singleton {
    id: notifs

    property var toasts: []

    // Suppressed arrivals never shown yet (panel was open). Flushed
    // into toasts on panel close. Pure transient feedback (OSD)
    // never pends: stale volume % popping later is just noise.
    property var pending: []

    // While the control panel is open its history is on screen:
    // live cards would only ghost under it, so the server holds
    // them for history instead of popping. Set by the panel.
    property bool suppressToasts: false

    // Panel closed: show what arrived while it was open (newest
    // first, toast cap respected; overflow stays history-only).
    // Marks everything read: it was all on screen in the list.
    function flushPending(): void {
        const room = Math.max(0, 5 - notifs.toasts.length)

        notifs.toasts = [...notifs.pending.slice(0, room), ...notifs.toasts]
        notifs.pending = []
        notifs.readCount = notifs.history.length
    }

    // History for the notification center. Snapshots carry plain
    // display data PLUS the live server object (for action buttons).
    // Snapshots are taken for every stored notification, including
    // DND-suppressed ones (so the center shows what you missed) -
    // except those arrive already dead (live: null, no buttons).
    property var history: []

    // Items arrived since the last mark-as-read. Derived from the
    // list itself so dismiss/clear can never desync the badge.
    property int readCount: 0
    readonly property int unread: Math.max(0, history.length - readCount)

    // Visual hide only: the server object stays resident (and its
    // actions invokable) until the history row goes away.
    function hideToast(n): void {
        notifs.toasts = notifs.toasts.filter(t => t !== n)
    }

    // Hide them all (opening a popup): anything already on screen
    // would end up buried under the new window. Rows stay.
    function hideAllToasts(): void {
        notifs.toasts = []
    }

    function dropLive(item): void {
        if (!item || !item.live)
            return

        // A dead sender's object can throw here; the row removal
        // below must still run, so never let it propagate.
        try {
            item.live.dismiss()
        } catch (_) {
        }
    }

    // A server object that died outside history (toast click,
    // synchronous replace, live-cap bump): its row's buttons would
    // be dead, so the row goes too. Never pops later either.
    function forgetLive(n): void {
        notifs.history = notifs.history.filter(h => h.live !== n)
        notifs.pending = notifs.pending.filter(t => t !== n)
        notifs.readCount = Math.min(notifs.readCount, notifs.history.length)
    }

    function filepathOf(notification): string {
        const hints = notification?.hints
        const path = hints && typeof hints["filepath"] === "string"
            ? hints["filepath"] : ""

        return path
    }

    // File-backed notifications (screenshots): the sender is already
    // gone (fire-and-forget notify), so Open/Copy run here instead of
    // relaying to a dead process. Anything else invokes normally.
    // Returns true when handled natively (caller dismisses the toast).
    function activateAction(notification, action): bool {
        const path = notifs.filepathOf(notification)
        const id = action?.identifier ?? ""

        if (path !== "" &&
                (id === "open" || id === "path" || id === "default")) {
            if (id === "path")
                Quickshell.execDetached(["sh", "-c",
                    'printf "%s" "$1" | wl-copy', "qs", path])
            else
                Quickshell.execDetached(["xdg-open", path])

            return true
        }

        // Same dead-sender exposure as dropLive: never let a dead
        // relay abort the caller's row handling.
        try {
            action.invoke()
        } catch (_) {
        }

        return false
    }

    function clearHistory(): void {
        for (const h of history)
            notifs.dropLive(h)

        history = []
        readCount = 0
    }

    function dismissHistoryAt(i: int): void {
        if (i < 0 || i >= history.length)
            return

        notifs.dropLive(history[i])
        history = history.filter((_, idx) => idx !== i)
        readCount = Math.min(readCount, history.length)
    }

    function snapshot(n): var {
        const cands = [n.image, n.appIcon]
        const hit = cands.find(s => typeof s === "string" && s !== "")

        return {
            app: n.appName ?? "",
            summary: n.summary ?? "",
            body: n.body ?? "",
            icon: hit ?? "",
            critical: n.urgency === NotificationUrgency.Critical,
            time: new Date(),
            syncId: n.hints
                ? n.hints["x-canonical-private-synchronous"]
                : undefined,
            live: Modes.dndActive ? null : n
        }
    }

    NotificationServer {
        id: server

        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true

        onNotification: notification => {
            const syncId = notification.hints
                ? notification.hints["x-canonical-private-synchronous"]
                : undefined

            // Synchronous replace: retire any live toast carrying
            // the same id before showing the new one.
            if (syncId !== undefined) {
                for (const old of notifs.toasts) {
                    const oldId = old.hints
                        ? old.hints["x-canonical-private-synchronous"]
                        : undefined

                    if (oldId === syncId) {
                        old.dismiss()
                        notifs.forgetLive(old)
                    }
                }
            }

            // History snapshot for the notification center (includes
            // DND-suppressed ones, so it shows what you missed).
            // Pure transient feedback (a synchronous replace id AND
            // no actions: volume/brightness OSD, progress spam) is
            // shown but never stored. Actionable replacers
            // (screenshot Open/Copy) ARE stored, superseding their
            // own older rows.
            if (syncId === undefined || notification.actions.length > 0) {
                let next = [notifs.snapshot(notification), ...notifs.history]

                if (syncId !== undefined) {
                    for (const h of next.slice(1)) {
                        if (h.syncId === syncId)
                            notifs.dropLive(h)
                    }

                    next = [next[0], ...next.slice(1).filter(
                        h => h.syncId !== syncId)]
                }

                for (const h of next.slice(30))
                    notifs.dropLive(h)

                notifs.history = next.slice(0, 30)
            }

            // DND: never pop up (mako parity: invisible mode), except
            // our own mode toggles, which must confirm both directions.
            // The snapshot above still lands in the center.
            if (Modes.dndActive && notification.appName !== "dnd" &&
                    notification.appName !== "caffeine") {
                notification.tracked = false
                return
            }

            notification.tracked = true
            notification.closed.connect(() => {
                notifs.toasts = notifs.toasts.filter(t => t !== notification)
                notifs.pending = notifs.pending.filter(t => t !== notification)
            })

            // Suppressed (panel open): resident for history, no card.
            // Storable ones pend for a retro-pop on panel close.
            if (notifs.suppressToasts) {
                if (syncId === undefined || notification.actions.length > 0) {
                    notifs.pending = [notification, ...notifs.pending].slice(0, 5)
                }

                return
            }

            const next = [notification, ...notifs.toasts].slice(0, 5)
            const dropped = notifs.toasts.filter(t => !next.includes(t))

            notifs.toasts = next

            for (const old of dropped) {
                old.dismiss()
                notifs.forgetLive(old)
            }
        }
    }
}
