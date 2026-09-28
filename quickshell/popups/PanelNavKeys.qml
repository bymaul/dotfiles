import QtQuick
// Shared vim-style keys for panel popups. Use when the popup exposes the
// panel interface (stepVertical/adjustSelected/focusNext/focusPrev/
// activateSelected) - ControlPanel and NotificationHistory do.
// List popups backed by a ListView/GridView (Wifi, Launcher, Clipboard,
// Emoji, Bluetooth) use BasePopup.stepListView/clampListView/selectInList
// with their own Shortcuts instead; bespoke models (Settings tabs,
// Calendar months, Power single-keys) hand-roll.
Item {
    id: keys
    required property var host
    required property var panel
    // Exactly one key set must be live: the control panel's when history is
    // hidden, the history window's when shown (it takes surface focus).
    property bool navActive: true
    Shortcut { sequence: "j"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.stepVertical(1) }
    Shortcut { sequence: "k"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.stepVertical(-1) }
    Shortcut { sequence: "Down"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.stepVertical(1) }
    Shortcut { sequence: "Up"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.stepVertical(-1) }
    Shortcut { sequence: "h"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.adjustSelected(-1) }
    Shortcut { sequence: "l"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.adjustSelected(1) }
    Shortcut { sequence: "Left"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.adjustSelected(-1) }
    Shortcut { sequence: "Right"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.adjustSelected(1) }
    Shortcut { sequence: "Tab"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.focusNext() }
    Shortcut { sequence: "Shift+Tab"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.focusPrev() }
    Shortcut { sequence: "Return"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.activateSelected() }
    Shortcut { sequence: "Space"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.activateSelected() }
    Shortcut { sequence: "m"; enabled: keys.host.visible && keys.navActive; onActivated: keys.panel.toggleVolumeMute() }
}
