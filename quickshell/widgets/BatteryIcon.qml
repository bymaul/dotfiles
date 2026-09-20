import QtQuick
import Quickshell.Services.UPower
import "../services" as Services
Item {
    id: root
    visible: Services.Power.hasBattery
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: label.width
    implicitHeight: label.height
    width: label.width
    height: label.height
    readonly property real level: Services.Power.level
    readonly property bool charging: Services.Power.battery?.state === UPowerDeviceState.Charging
    Text {
        id: label
        text: {
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
        color: Services.Power.levelColor(root.level * 100)
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px13
    }
}
