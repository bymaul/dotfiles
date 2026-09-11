import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../Palette.js" as Palette

Item {
    id: battery

    visible: battery.laptopBattery !== null

    width: batteryText.width
    height: batteryText.height

    property var laptopBattery:
        UPower.devices.values.find(
            device => device.isLaptopBattery
        )

    Text {
        id: batteryText

        property real level:
            battery.laptopBattery?.percentage ?? 0

        property bool charging:
            battery.laptopBattery?.state ===
            UPowerDeviceState.Charging

        text: {
            if (!battery.laptopBattery)
                return "󰂑 --%"

            // UPower percentage is 0.0 -> 1.0
            const p = level * 100

            let icon

            if (charging)
                icon = "󰂄"
            else if (p >= 90)
                icon = "󰁹"
            else if (p >= 70)
                icon = "󰂂"
            else if (p >= 50)
                icon = "󰁾"
            else if (p >= 30)
                icon = "󰁼"
            else if (p >= 10)
                icon = "󰁺"
            else
                icon = "󰂎"

            return `${icon} ${Math.round(p)}%`
        }

        color: {
            if (!battery.laptopBattery)
                return Palette.fg

            const p = level * 100

            if (p < 10)
                return Palette.danger

            if (p < 20)
                return Palette.warn

            return Palette.fg
        }

        font.family: Palette.font
        font.pixelSize: Palette.px13
    }
}