import QtQuick

Item {
    id: keys
    required property var host
    property bool navActive: true
    property var step: null
    property var confirm: null
    property var remove: null

    Shortcut { sequence: "j"; enabled: keys.host.visible && keys.navActive; onActivated: { if (keys.step) keys.step(1); } }
    Shortcut { sequence: "k"; enabled: keys.host.visible && keys.navActive; onActivated: { if (keys.step) keys.step(-1); } }
    Shortcut { sequence: "Down"; enabled: keys.host.visible && keys.navActive; onActivated: { if (keys.step) keys.step(1); } }
    Shortcut { sequence: "Up"; enabled: keys.host.visible && keys.navActive; onActivated: { if (keys.step) keys.step(-1); } }
    Shortcut { sequence: "Return"; enabled: keys.host.visible && keys.navActive; onActivated: { if (keys.confirm) keys.confirm(); } }
    Shortcut { sequence: "Enter"; enabled: keys.host.visible && keys.navActive; onActivated: { if (keys.confirm) keys.confirm(); } }
    Shortcut { sequence: "Space"; enabled: keys.host.visible && keys.navActive; onActivated: { if (keys.confirm) keys.confirm(); } }
    Shortcut { sequence: "d"; enabled: keys.host.visible && keys.navActive && keys.remove !== null; onActivated: { if (keys.remove) keys.remove(); } }
    Shortcut { sequence: "Delete"; enabled: keys.host.visible && keys.navActive && keys.remove !== null; onActivated: { if (keys.remove) keys.remove(); } }
}
