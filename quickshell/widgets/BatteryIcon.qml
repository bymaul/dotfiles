import QtQuick
import Quickshell.Services.UPower
import "../components"
import "../services" as Services
BarIcon {
    id: root
    property var bar
    visible: Services.Power.hasBattery
    anchors.verticalCenter: parent.verticalCenter
    showPointer: false
    readonly property real level: Services.Power.level
    readonly property bool charging: Services.Power.battery?.state === UPowerDeviceState.Charging
    glyph: {
        const p = root.level * 100;
        let icon = "󰂎";
        if (root.charging)
            icon = "󰂄";
        else if (p >= 90)
            icon = "󰁹";
        else if (p >= 70)
            icon = "󰂂";
        else if (p >= 50)
            icon = "󰁾";
        else if (p >= 30)
            icon = "󰁼";
        else if (p >= 10)
            icon = "󰁺";
        return `${icon} ${Math.round(p)}%`;
    }
    glyphColor: Services.Power.levelColor(root.level * 100)
    tipText: Services.Power.statusLine
    tipAnchor: root.bar
    onClicked: bar.togglePower()
}
