import QtQuick
import "../components"
import "../services" as Services

Item {
    id: root
    required property var bar

    function unlocked(): bool {
        return root.bar.unlocked();
    }

    BarShortcut {
        name: "control"; description: "Open the control panel"
        onPressed: { if (root.unlocked()) root.bar.togglePopup("control"); }
    }
    BarShortcut {
        name: "calendar"; description: "Open the calendar"
        onPressed: { if (root.unlocked()) root.bar.togglePopup("calendar"); }
    }
    BarShortcut {
        name: "power"; description: "Open the power menu"
        onPressed: { if (root.unlocked()) root.bar.togglePopup("power"); }
    }
    BarShortcut {
        name: "settings"; description: "Open settings"
        onPressed: { if (root.unlocked()) root.bar.togglePopup("settings"); }
    }

    QsShortcut {
        name: "launcher"; description: "Open the application launcher"
        onPressed: { if (root.unlocked()) root.bar.togglePopup("launcher"); }
    }
    QsShortcut {
        name: "clipboard"; description: "Open the clipboard history picker"
        onPressed: { if (root.unlocked()) root.bar.togglePopup("clipboard"); }
    }
    QsShortcut {
        name: "emoji"; description: "Open the emoji picker"
        onPressed: { if (root.unlocked()) root.bar.togglePopup("emoji"); }
    }

    QsShortcut {
        name: "lock"; description: "Lock the session"
        onPressed: root.bar.lockScreen()
    }
    QsShortcut {
        name: "powerkey"; description: "Handle the power key per settings"
        onPressed: root.bar.handlePowerKey()
    }
    QsShortcut {
        name: "caffeine"; description: "Toggle caffeine mode (block idle)"
        onPressed: Services.Modes.toggleCaffeine()
    }
    QsShortcut {
        name: "dnd"; description: "Toggle do-not-disturb mode"
        onPressed: Services.Modes.toggleDnd()
    }

    QsShortcut {
        name: "screenshot-area"; description: "Screenshot a selected area"
        onPressed: { if (root.unlocked()) root.bar.screenshot("area"); }
    }
    QsShortcut {
        name: "screenshot-full"; description: "Screenshot the full screen"
        onPressed: { if (root.unlocked()) root.bar.screenshot("full"); }
    }
    QsShortcut {
        name: "screenshot-window"; description: "Screenshot the active window"
        onPressed: { if (root.unlocked()) root.bar.screenshot("window"); }
    }

    QsShortcut {
        name: "volume-up"; description: "Raise the volume"
        onPressed: Services.Media.volumeUp()
    }
    QsShortcut {
        name: "volume-down"; description: "Lower the volume"
        onPressed: Services.Media.volumeDown()
    }
    QsShortcut {
        name: "volume-mute"; description: "Mute the volume"
        onPressed: Services.Media.toggleVolumeMute()
    }
    QsShortcut {
        name: "mic-mute"; description: "Mute the microphone"
        onPressed: Services.Media.toggleMicMute()
    }

    QsShortcut {
        name: "media-toggle"; description: "Play or pause media"
        onPressed: Services.Media.mediaToggle()
    }
    QsShortcut {
        name: "media-next"; description: "Next media track"
        onPressed: Services.Media.mediaNext()
    }
    QsShortcut {
        name: "media-prev"; description: "Previous media track"
        onPressed: Services.Media.mediaPrev()
    }

    QsShortcut {
        name: "brightness-up"; description: "Raise the brightness"
        onPressed: Services.Media.brightnessUp()
    }
    QsShortcut {
        name: "brightness-down"; description: "Lower the brightness"
        onPressed: Services.Media.brightnessDown()
    }
}
