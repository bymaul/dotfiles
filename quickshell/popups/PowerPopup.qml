import QtQuick
import Quickshell
import "../components"
import "../services" as Services
BasePopup {
    id: root
    implicitWidth: Services.Theme.popupWidth
    implicitHeight: 16 + statusText.height + Services.Theme.popupSpacing + (xfceWarn.visible ? xfceWarn.height + Services.Theme.popupSpacing : 0) + powerGrid.height + Services.Theme.popupSpacing + hint.implicitHeight
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
        root.execPower(["systemctl", "poweroff", "-i"]);
    }
    function reboot(): void {
        root.execPower(["systemctl", "reboot", "-i"]);
    }
    function suspend(): void {
        Services.Power.lock();
        root.execPower(["systemctl", "suspend", "-i"]);
    }
    function hibernate(): void {
        Services.Power.lock();
        root.execPower(["systemctl", "hibernate", "-i"]);
    }
    function lock(): void {
        bar.lockScreen();
    }
    function logout(): void {
        root.execPower(["hyprctl", "dispatch", "hl.dsp.exit()"]);
    }
    onVisibleChanged: {
        if (visible)
            Services.Power.refreshInhibitors();
    }
    PopupCard {
        Text {
            id: statusText
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: Services.Power.statusLine
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px12
        }
        Text {
            id: xfceWarn
            visible: Services.Power.xfceBlocking
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "xfce4-power-manager is still running and blocks logind - uninstall it"
            color: Services.Theme.danger
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px11
        }
        Grid {
            id: powerGrid
            width: parent.width
            columns: 2
            columnSpacing: Services.Theme.popupSpacing
            rowSpacing: Services.Theme.popupSpacing
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
