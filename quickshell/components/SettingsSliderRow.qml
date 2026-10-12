import QtQuick
import "../services" as Services

SettingsRow {
    id: root
    property real sliderMinimum: 0
    property real sliderMaximum: 1
    property real sliderValue: 0
    property real sliderStep: 0
    signal sliderMoved(real newValue)
    SliderBar {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        minimum: root.sliderMinimum
        maximum: root.sliderMaximum
        wheelStep: root.sliderStep
        value: root.sliderValue
        onSliderMoved: value => root.sliderMoved(value)
    }
}
