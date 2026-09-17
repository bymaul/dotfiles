import QtQuick
Item {
    id: keys
    required property var host
    required property var panel
    Shortcut { sequence: "j"; enabled: keys.host.visible; onActivated: keys.panel.stepVertical(1) }
    Shortcut { sequence: "k"; enabled: keys.host.visible; onActivated: keys.panel.stepVertical(-1) }
    Shortcut { sequence: "Down"; enabled: keys.host.visible; onActivated: keys.panel.stepVertical(1) }
    Shortcut { sequence: "Up"; enabled: keys.host.visible; onActivated: keys.panel.stepVertical(-1) }
    Shortcut { sequence: "h"; enabled: keys.host.visible; onActivated: keys.panel.adjustSelected(-1) }
    Shortcut { sequence: "l"; enabled: keys.host.visible; onActivated: keys.panel.adjustSelected(1) }
    Shortcut { sequence: "Left"; enabled: keys.host.visible; onActivated: keys.panel.adjustSelected(-1) }
    Shortcut { sequence: "Right"; enabled: keys.host.visible; onActivated: keys.panel.adjustSelected(1) }
    Shortcut { sequence: "Tab"; enabled: keys.host.visible; onActivated: keys.panel.focusNext() }
    Shortcut { sequence: "Shift+Tab"; enabled: keys.host.visible; onActivated: keys.panel.focusPrev() }
    Shortcut { sequence: "Return"; enabled: keys.host.visible; onActivated: keys.panel.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: keys.host.visible; onActivated: keys.panel.activateSelected() }
    Shortcut { sequence: "Space"; enabled: keys.host.visible; onActivated: keys.panel.activateSelected() }
    Shortcut { sequence: "m"; enabled: keys.host.visible; onActivated: keys.panel.toggleVolumeMute() }
}
