//@ pragma IconTheme Adwaita

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
    readonly property string focusedName: Hyprland.focusedMonitor?.name ?? ""
    Bar {
        id: bar
        lockContext: lockContext
        sessionLock: sessionLock
        screenshotTool: screenshotTool
    }
    Variants {
        model: {
            const main = Services.Settings.mainScreen(Quickshell.screens, focusedName);
            const mainName = main && main.name ? main.name : "";
            return Quickshell.screens.filter(s => s.name !== mainName);
        }
        SlimBar {
            required property var modelData
            targetScreen: modelData
        }
    }

    IpcHandler {
        target: "bar"
        function closePopups(): void {
            bar.closePopups();
        }
        function toggleControl(): void {
            bar.toggleControl();
        }
        function togglePower(): void {
            bar.togglePower();
        }
        function toggleEmoji(): void {
            bar.toggleEmoji();
        }
        function settings(): void {
            bar.toggleSettings();
        }
            function settingsState(): string {
                return JSON.stringify({monitors: Services.Settings.monitors, configs: Services.Settings.monitorConfigs, lastApply: Services.Settings.lastApplyMsg, monitorsReady: Services.Settings.monitorsReady, canDisableEdp: Services.Settings.monitors.length > 0 ? Services.Settings.canDisableMonitor(Services.Settings.monitors[0].name) : null});
            }
        function panelStep(dir: int): void {
            bar.panelStep(dir);
        }
        function panelActivate(): void {
            bar.panelActivate();
        }
        function lock(): void {
            bar.lockScreen();
        }
        function powerKey(): void {
            bar.handlePowerKey();
        }
        function screenshot(mode: string): void {
            bar.screenshot(mode);
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusiveZone: -1
            color: Services.Theme.bg
            WlrLayershell.namespace: "wallpaper"
            WlrLayershell.layer: WlrLayer.Background
            Image {
                anchors.fill: parent
                source: Services.Wallpaper.source
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                sourceSize.width: modelData.width
                sourceSize.height: modelData.height
            }
        }
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
            }
        }
    }
    ToastStack {
        id: toastStack
        bar: bar
    }
    Screenshot {
        id: screenshotTool
    }
}
