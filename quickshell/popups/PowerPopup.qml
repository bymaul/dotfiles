import QtQuick
import Quickshell
import "../components"
import "../Palette.js" as Palette
BasePopup {
    id: root
    implicitWidth: Palette.popupWidth
    implicitHeight: 16 + powerGrid.height + Palette.popupSpacing + hint.implicitHeight
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }
    Shortcut { sequence: "s"; enabled: root.visible; onActivated: root.powerOff() }
    Shortcut { sequence: "r"; enabled: root.visible; onActivated: root.reboot() }
    Shortcut { sequence: "u"; enabled: root.visible; onActivated: root.suspend() }
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.hibernate() }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.lock() }
    Shortcut { sequence: "e"; enabled: root.visible; onActivated: root.logout() }
    function execPower(cmd: var): void {
        bar.closePopups();
        Quickshell.execDetached(cmd);
    }
    function powerOff(): void {
        root.execPower(["systemctl", "poweroff"]);
    }
    function reboot(): void {
        root.execPower(["systemctl", "reboot"]);
    }
    function suspend(): void {
        root.execPower(["systemctl", "suspend"]);
    }
    function hibernate(): void {
        root.execPower(["systemctl", "hibernate"]);
    }
    function lock(): void {
        bar.lockScreen();
    }
    function logout(): void {
        root.execPower(["hyprctl", "dispatch", "hl.dsp.exit()"]);
    }
    PopupCard {
        Grid {
            id: powerGrid
            width: parent.width
            columns: 2
            columnSpacing: Palette.popupSpacing
            rowSpacing: Palette.popupSpacing
            ActionTile { glyph: "󰐥"; label: "Power off"; onActionClicked: root.powerOff() }
            ActionTile { glyph: "󰜉"; label: "Reboot"; onActionClicked: root.reboot() }
            ActionTile { glyph: "󰤄"; label: "Suspend"; onActionClicked: root.suspend() }
            ActionTile { glyph: "󰋊"; label: "Hibernate"; onActionClicked: root.hibernate() }
            ActionTile { glyph: "󰌾"; label: "Lock"; onActionClicked: root.lock() }
            ActionTile { glyph: "󰍃"; label: "Logout"; onActionClicked: root.logout() }
        }
        HintText {
            id: hint
            text: "s power off · r reboot · u suspend\nh hibernate · l lock · e logout"
        }
    }
}
