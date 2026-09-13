import QtQuick
import Quickshell.Services.UPower
import "../Palette.js" as Palette
Item {
    id: root
    visible: root.laptopBattery != null
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: label.width
    implicitHeight: label.height
    width: label.width
    height: label.height
    property var laptopBattery: UPower.devices.values.find(device => device.isLaptopBattery)
    readonly property real level: root.laptopBattery?.percentage ?? 0
    readonly property bool charging: root.laptopBattery?.state === UPowerDeviceState.Charging
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
        color: {
            const p = root.level * 100;
            if (p < 10)
                return Palette.danger;
            if (p < 20)
                return Palette.warn;
            return Palette.fg;
        }
        font.family: Palette.font
        font.pixelSize: Palette.px13
    }
}
