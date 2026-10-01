import QtQuick
import Quickshell
import "../popups"
import "../services" as Services

Item {
    id: root
    required property var bar
    required property var clock

    readonly property alias historyPanel: historyPanel
    readonly property alias controlPanel: controlPanelPopup

    property bool settingsRequested: false
    property bool launcherRequested: false
    property bool clipboardRequested: false
    property bool emojiRequested: false
    property string pendingOpen: ""
    property var pendingReturnTo: null

    readonly property var settingsPopup: settingsLoader.item
    readonly property var launcherPopup: launcherLoader.item
    readonly property var clipboardPopup: clipboardLoader.item
    readonly property var emojiPopup: emojiLoader.item

    readonly property var allPopups: [calendarPopup, controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, root.settingsPopup, root.launcherPopup, root.clipboardPopup, root.emojiPopup, historyPanel]
    readonly property var exclusivePopups: [calendarPopup, controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, root.settingsPopup, root.launcherPopup, root.clipboardPopup, root.emojiPopup]
    readonly property var rightPopups: [calendarPopup, controlPanelPopup, wifiPopup, bluetoothPopup, powerPopup, root.settingsPopup, historyPanel]

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
        case "settings": return root.settingsPopup;
        case "launcher": return root.launcherPopup;
        case "clipboard": return root.clipboardPopup;
        case "emoji": return root.emojiPopup;
        default: return null;
        }
    }
    function ensurePopup(name: string): var {
        if (name === "settings")
            root.settingsRequested = true;
        else if (name === "launcher")
            root.launcherRequested = true;
        else if (name === "clipboard")
            root.clipboardRequested = true;
        else if (name === "emoji")
            root.emojiRequested = true;
        return root.popupByName(name);
    }
    function flushPending(): void {
        if (root.pendingOpen === "")
            return;
        const target = root.popupByName(root.pendingOpen);
        if (!target)
            return;
        const back = root.pendingReturnTo;
        root.pendingOpen = "";
        root.pendingReturnTo = null;
        root.openExclusive(target, back);
    }
    function closePopups(): void {
        for (const p of root.exclusivePopups) {
            if (p)
                p.visible = false;
        }
    }
    function togglePopup(name: string): void {
        const target = root.ensurePopup(name);
        if (target) {
            root.pendingOpen = "";
            root.pendingReturnTo = null;
            root.openExclusive(target);
        } else {
            root.pendingOpen = name;
            root.pendingReturnTo = null;
        }
    }
    function openFromPanel(name: string): void {
        const target = root.ensurePopup(name);
        if (target) {
            root.pendingOpen = "";
            root.pendingReturnTo = null;
            root.openExclusive(target, controlPanelPopup);
        } else {
            root.pendingOpen = name;
            root.pendingReturnTo = controlPanelPopup;
        }
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
    LazyLoader {
        id: settingsLoader
        active: root.settingsRequested
        component: Component {
            SettingsPopup {
                bar: root.bar
            }
        }
        onItemChanged: root.flushPending()
    }
    LazyLoader {
        id: launcherLoader
        active: root.launcherRequested
        component: Component {
            LauncherPopup {
                bar: root.bar
            }
        }
        onItemChanged: root.flushPending()
    }
    LazyLoader {
        id: clipboardLoader
        active: root.clipboardRequested
        component: Component {
            ClipboardPopup {
                bar: root.bar
            }
        }
        onItemChanged: root.flushPending()
    }
    LazyLoader {
        id: emojiLoader
        active: root.emojiRequested
        component: Component {
            EmojiPopup {
                bar: root.bar
            }
        }
        onItemChanged: root.flushPending()
    }
}
