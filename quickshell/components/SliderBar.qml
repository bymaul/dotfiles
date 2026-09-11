import QtQuick
import "../Palette.js" as Palette

Item {
    id: slider

    required property real value
    property real minimum: 0
    property real maximum: 1

    signal sliderMoved(real newValue)

    height: 24

    readonly property real fraction: Math.max(0, Math.min(1,
        (slider.value - slider.minimum) /
        (slider.maximum - slider.minimum)))

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter

        width: slider.width
        height: 6

        radius: 0

        color: Palette.onAccent
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter

        width: slider.width * slider.fraction
        height: 6

        radius: 0

        color: Palette.accent
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter

        x: slider.width * slider.fraction - 5

        width: 10
        height: 18

        radius: 0

        color: Palette.fg
    }

    MouseArea {
        anchors.fill: parent

        function adjust(mouse: var): void {
            slider.sliderMoved(
                slider.minimum +
                Math.max(0, Math.min(1, mouse.x / slider.width)) *
                (slider.maximum - slider.minimum)
            )
        }

        onPressed: mouse => adjust(mouse)
        onPositionChanged: mouse => adjust(mouse)

        // Match the bar volume icon: scroll steps 5% of range.
        onWheel: event => {
            const step = (event.angleDelta.y > 0 ? 0.05 : -0.05) *
                (slider.maximum - slider.minimum)

            slider.sliderMoved(
                Math.max(slider.minimum,
                    Math.min(slider.maximum, slider.value + step))
            )
        }
    }
}