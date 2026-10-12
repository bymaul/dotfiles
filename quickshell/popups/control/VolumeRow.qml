import QtQuick
import "../../services" as Services

SliderRow {
    rowIndex: popup.volumeIdx()
    glyph: popup.audioSink?.audio?.muted ? "󰝟" : "󰕾"
    sliderMaximum: Services.Theme.volumeMax
    sliderStep: Services.Theme.volumeStep
    sliderValue: popup.audioSink?.audio?.volume ?? 0
    valueLabel: Math.round((popup.audioSink?.audio?.volume ?? 0) * 100) + "%"
    onSliderMoved: value => {
        const audio = popup.audioSink?.audio;
        if (audio)
            audio.volume = value;
    }
    onGlyphClicked: popup.toggleVolumeMute()
}
