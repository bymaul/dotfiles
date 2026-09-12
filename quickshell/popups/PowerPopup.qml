import QtQuick
import Quickshell
import "../components"
import "../Palette.js" as Palette

BasePopup {
    id: powerPopup

    implicitWidth: Palette.popupWidth
    implicitHeight: 16 + powerGrid.height + Palette.popupSpacing + hintText.implicitHeight

    function execPower(cmd: var) {
        bar.closePopups();
        Quickshell.execDetached(cmd);
    }

    function powerOff(): void {
        powerPopup.execPower(["systemctl", "poweroff"]);
    }

    function reboot(): void {
        powerPopup.execPower(["systemctl", "reboot"]);
    }

    function suspend(): void {
        powerPopup.execPower(["systemctl", "suspend"]);
    }

    function hibernate(): void {
        powerPopup.execPower(["systemctl", "hibernate"]);
    }

    function lock(): void {
        powerPopup.execPower(["hyprlock"]);
    }

    function logout(): void {
        powerPopup.execPower(["hyprctl", "dispatch", "hl.dsp.exit()"]);
    }

    // Scoped to the open menu: unguarded, these would fire while
    // typing anywhere a popup holds focus (e.g. s/r/u/h/l/e in the
    // Wi-Fi password field).
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

        border.width: 0

        Column {
            anchors {
                fill: parent
                margins: Palette.popupPadding
            }

            spacing: Palette.popupSpacing

            Grid {
                id: powerGrid

                width: parent.width

                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                ActionTile {
                    glyph: "󰐥"
                    label: "Power off"

                    onActionClicked: powerPopup.powerOff()
                }

                ActionTile {
                    glyph: "󰜉"
                    label: "Reboot"

                    onActionClicked: powerPopup.reboot()
                }

                ActionTile {
                    glyph: "󰤄"
                    label: "Suspend"

                    onActionClicked: powerPopup.suspend()
                }

                ActionTile {
                    glyph: "󰋊"
                    label: "Hibernate"

                    onActionClicked: powerPopup.hibernate()
                }

                ActionTile {
                    glyph: "󰌾"
                    label: "Lock"

                    onActionClicked: powerPopup.lock()
                }

                ActionTile {
                    glyph: "󰍃"
                    label: "Logout"

                    onActionClicked: powerPopup.logout()
                }
            }

            Text {
                id: hintText

                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "s power off · r reboot· u suspend\nh hibernate · l lock · e logout"

                wrapMode: Text.WordWrap
                color: Palette.dim
                font.family: Palette.font
                font.pixelSize: Palette.px10
            }
        }
    }
}
