import QtQuick
import "../../services" as Services

SliderRow {
    rowIndex: 0
    visible: Services.Media.brightnessAvailable
    glyph: "󰃟"
    sliderValue: Services.Media.brightness / 100
    valueLabel: Math.round(Services.Media.brightness) + "%"
    onSliderMoved: value => Services.Media.setBrightness(value * 100, true)
}
