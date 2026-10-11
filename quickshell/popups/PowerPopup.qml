import QtQuick
import Quickshell
import "../components"
import "../services" as Services
BasePopup {
    id: root
    implicitWidth: Services.Theme.popupWidth
    implicitHeight: 16 + powerGrid.height
    Shortcut { sequence: "s"; enabled: root.visible; onActivated: root.powerOff() }
    Shortcut { sequence: "r"; enabled: root.visible; onActivated: root.reboot() }
    Shortcut { sequence: "u"; enabled: root.visible; onActivated: root.suspend() }
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.hibernate() }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.lock() }
    Shortcut { sequence: "e"; enabled: root.visible; onActivated: root.logout() }
    function execPower(cmd: var): void {
        if (Array.isArray(cmd) && cmd[0] === "systemctl" && !Services.Power.hasLogind) {
            bar.closePopups();
            Services.Notifs.notify({app: "power", summary: "Power action unavailable", body: "systemctl not found", timeout: Services.Theme.osdTimeout});
            return;
        }
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
        Grid {
            id: powerGrid
            width: parent.width
            columns: 2
            columnSpacing: Services.Theme.popupSpacing
            rowSpacing: Services.Theme.popupSpacing
            Tile { glyph: "󰐥"; label: "Power off [s]"; columns: 2; onClicked: root.powerOff() }
            Tile { glyph: "󰜉"; label: "Reboot [r]"; columns: 2; onClicked: root.reboot() }
            Tile { glyph: "󰤄"; label: "Suspend [u]"; columns: 2; onClicked: root.suspend() }
            Tile { glyph: "󰋊"; label: "Hibernate [h]"; columns: 2; onClicked: root.hibernate() }
            Tile { glyph: "󰌾"; label: "Lock [l]"; columns: 2; onClicked: root.lock() }
            Tile { glyph: "󰍃"; label: "Logout [e]"; columns: 2; onClicked: root.logout() }
        }
    }
}
