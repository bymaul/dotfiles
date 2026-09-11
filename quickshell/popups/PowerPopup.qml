import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Hyprland
import "../components"
import "../Palette.js" as Palette

PopupWindow {
    id: powerPopup

    required property var bar

    anchor.window: bar

    anchor.rect.x: bar.width - width - Palette.popupMargin
    anchor.rect.y: bar.height + Palette.popupTopGap

    implicitWidth: Palette.popupWidth
    implicitHeight: 178

    visible: false

    color: "transparent"

    HyprlandFocusGrab {
        id: powerGrab

        windows: [powerPopup]

        // No grabFocus: it dismisses on any grab break (e.g. toast
        // expiry). Assert active from the timer, not bound to visible.
        onCleared: powerPopup.visible = false
    }

    Timer {
        interval: 100
        running: powerPopup.visible
        repeat: false

        onTriggered: powerGrab.active = true
    }

    function execPower(cmd: var) {
        bar.closePopups()
        Quickshell.execDetached(cmd)
    }

    function powerOff(): void {
        powerPopup.execPower(["systemctl", "poweroff"])
    }

    function reboot(): void {
        powerPopup.execPower(["systemctl", "reboot"])
    }

    function suspend(): void {
        powerPopup.execPower(["systemctl", "suspend"])
    }

    function hibernate(): void {
        powerPopup.execPower(["systemctl", "hibernate"])
    }

    function lock(): void {
        powerPopup.execPower(["hyprlock"])
    }

    function logout(): void {
        powerPopup.execPower(["hyprctl", "dispatch", "hl.dsp.exit()"])
    }

    // Single-key actions (Super+Shift+Q opens menu, press key).
    // Scoped to the open menu: without the guard these would fire
    // while typing anywhere once any popup holds focus (notably the
    // Wi-Fi password field, where s/r/u/h/l/e are ordinary letters).
    Shortcut {
        sequence: "s"
        enabled: powerPopup.visible
        onActivated: powerPopup.powerOff()
    }
    Shortcut {
        sequence: "r"
        enabled: powerPopup.visible
        onActivated: powerPopup.reboot()
    }
    Shortcut {
        sequence: "u"
        enabled: powerPopup.visible
        onActivated: powerPopup.suspend()
    }
    Shortcut {
        sequence: "h"
        enabled: powerPopup.visible
        onActivated: powerPopup.hibernate()
    }
    Shortcut {
        sequence: "l"
        enabled: powerPopup.visible
        onActivated: powerPopup.lock()
    }
    Shortcut {
        sequence: "e"
        enabled: powerPopup.visible
        onActivated: powerPopup.logout()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: bar.closePopups()
    }

    Rectangle {
        anchors.fill: parent

        radius: 0

        color: Palette.bg

        border.width: 1
        border.color: Palette.border

        Grid {
            anchors {
                fill: parent
                margins: 12
            }

            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            // POWER OFF
            ActionTile {
                glyph: "󰐥"
                label: "Power off"
                hint: "s"

                onActionClicked: powerPopup.powerOff()
            }

            // REBOOT
            ActionTile {
                glyph: "󰜉"
                label: "Reboot"
                hint: "r"

                onActionClicked: powerPopup.reboot()
            }

            // SUSPEND
            ActionTile {
                glyph: "󰤄"
                label: "Suspend"
                hint: "u"

                onActionClicked: powerPopup.suspend()
            }

            // HIBERNATE
            ActionTile {
                glyph: "󰋊"
                label: "Hibernate"
                hint: "h"

                onActionClicked: powerPopup.hibernate()
            }

            // LOCK
            ActionTile {
                glyph: "󰌾"
                label: "Lock"
                hint: "l"

                onActionClicked: powerPopup.lock()
            }

            // LOGOUT
            ActionTile {
                glyph: "󰍃"
                label: "Logout"
                hint: "e"

                onActionClicked: powerPopup.logout()
            }
        }
    }
}
