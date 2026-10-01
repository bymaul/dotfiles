//@ pragma IconTheme Adwaita
//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "widgets"
import "popups"
import "lock"
import "screenshot"
import "services" as Services

ShellRoot {
    Bar {
        id: bar
        lockContext: lockContext
        sessionLock: sessionLock
        screenshotTool: screenshotTool
    }
    Variants {
        model: {
            const main = Services.Settings.mainScreen(Quickshell.screens);
            const mainName = main && main.name ? main.name : "";
            return Quickshell.screens.filter(s => s && s.name && s.name !== mainName);
        }
        SlimBar {
            required property var modelData
            targetScreen: modelData
        }
    }

    IpcHandler {
        target: "bar"
        function closePopups(): void { bar.closePopups(); }
        function toggle(name: string): void { bar.togglePopup(name); }
        function lock(): void { bar.lockScreen(); }
        function powerKey(): void { bar.handlePowerKey(); }
        function screenshot(mode: string): void { bar.screenshot(mode); }
    }

    Variants {
        model: Quickshell.screens
        WallpaperWindow {}
    }
    LockContext {
        id: lockContext
        onUnlocked: sessionLock.locked = false
    }
    WlSessionLock {
        id: sessionLock
        WlSessionLockSurface {
            id: lockSurf
            LockSurface {
                anchors.fill: parent
                context: lockContext
                ownScreen: lockSurf.screen
                locked: lockSurf.visible || sessionLock.locked
            }
        }
    }
    NotificationStack {
        id: notifStack
        bar: bar
    }
    Screenshot {
        id: screenshotTool
    }
}
