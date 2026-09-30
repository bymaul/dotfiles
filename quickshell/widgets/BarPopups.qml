import QtQuick
import "../popups"
import "../services" as Services

Item {
    id: root
    required property var bar
    required property var clock

    readonly property alias historyPanel: historyPanel
    readonly property alias controlPanel: controlPanelPopup

    readonly property var allPopups: [calendarPopup, controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, settingsPopup, launcherPopup, clipboardPopup, emojiPopup, historyPanel]
    readonly property var exclusivePopups: [calendarPopup, controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, settingsPopup, launcherPopup, clipboardPopup, emojiPopup]
    readonly property var rightPopups: [calendarPopup, controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, settingsPopup, historyPanel]

    property int rightPopupBottom: {
        const top = Services.Theme.popupTopGap;
        let bottom = 0;
        for (const p of root.rightPopups) {
            if (p && p.visible && p.height > 0)
                bottom = Math.max(bottom, top + (p.extraTop ?? 0) + p.height);
        }
        return bottom;
    }
    property int rightPopupWidth: {
        let w = 0;
        for (const p of root.rightPopups) {
            if (p && p.visible)
                w = Math.max(w, p.width);
        }
        return w > 0 ? w : Services.Theme.popupWidth;
    }

    function popupByName(name: string): var {
        switch (name) {
        case "calendar": return calendarPopup;
        case "control": return controlPanelPopup;
        case "wifi": return wifiPopup;
        case "bluetooth": return bluetoothPopup;
        case "power": return powerPopup;
        case "settings": return settingsPopup;
        case "launcher": return launcherPopup;
        case "clipboard": return clipboardPopup;
        case "emoji": return emojiPopup;
        default: return null;
        }
    }
    function closePopups(): void {
        for (const p of root.exclusivePopups)
            p.visible = false;
    }
    function togglePopup(name: string): void {
        const target = root.popupByName(name);
        if (target)
            root.openExclusive(target);
    }
    function openFromPanel(name: string): void {
        const target = root.popupByName(name);
        if (target)
            root.openExclusive(target, controlPanelPopup);
    }
    function openExclusive(target, returnTo = null): void {
        if (!target)
            return;
        const open = !target.visible;
        root.closePopups();
        if (open) {
            if (returnTo && returnTo.anchor && returnTo.anchor.window)
                target.anchor.window = returnTo.anchor.window;
            else
                target.anchor.window = root.bar.currentPopupAnchor();
        }
        target.returnTo = open ? returnTo : null;
        target.visible = open;
        if (open && target.useGrab !== false && typeof target.regrab === "function")
            target.regrab();
    }
    function followPopupAnchor(anchor): void {
        for (const p of root.allPopups) {
            if (!p || !p.anchor || p.anchor.window === anchor)
                continue;
            if (p === historyPanel) {
                if (!p.visible) {
                    p.anchor.window = anchor;
                } else {
                    p.visible = false;
                    p.anchor.window = anchor;
                    p.rebindVisibility();
                }
                continue;
            }
            if (!p.visible) {
                p.anchor.window = anchor;
                continue;
            }
            p.visible = false;
            p.anchor.window = anchor;
            p.visible = true;
            if (typeof p.regrab === "function")
                p.regrab();
        }
    }
    function revealHistory(i: int): void {
        historyPanel.revealAt(i);
    }

    CalendarPopup {
        id: calendarPopup
        bar: root.bar
        clock: root.clock
    }
    ControlPanelPopup {
        id: controlPanelPopup
        bar: root.bar
        historyWindow: historyPanel
    }
    NotificationHistoryPopup {
        id: historyPanel
        bar: root.bar
        panel: controlPanelPopup
    }
    WifiPopup {
        id: wifiPopup
        bar: root.bar
    }
    BluetoothPopup {
        id: bluetoothPopup
        bar: root.bar
    }
    PowerPopup {
        id: powerPopup
        bar: root.bar
    }
    SettingsPopup {
        id: settingsPopup
        bar: root.bar
    }
    LauncherPopup {
        id: launcherPopup
        bar: root.bar
    }
    ClipboardPopup {
        id: clipboardPopup
        bar: root.bar
    }
    EmojiPopup {
        id: emojiPopup
        bar: root.bar
    }
}
