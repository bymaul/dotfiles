import QtQuick
import "../services" as Services
Item {
    id: root
    required property real value
    property real minimum: 0
    property real maximum: 1
    signal sliderMoved(real newValue)
    height: 24
    readonly property real fraction: {
        const range = root.maximum - root.minimum;
        return range <= 0 ? 0 : Services.Theme.clamp01((root.value - root.minimum) / range);
    }
    function setFromMouse(mouse: var): void {
        root.sliderMoved(root.minimum + Services.Theme.clamp01(mouse.x / root.width) * (root.maximum - root.minimum));
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.width
        height: 3
        color: Services.Theme.accentFg
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.width * root.fraction
        height: 3
        color: Services.Theme.accent
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.width * root.fraction - 2
        width: 4
        height: 14
        color: Services.Theme.fg
    }
    MouseArea {
        anchors.fill: parent
        onPressed: mouse => root.setFromMouse(mouse)
        onPositionChanged: mouse => {
            if (pressed)
                root.setFromMouse(mouse);
        }
        onWheel: event => {
            const step = (event.angleDelta.y > 0 ? 0.05 : -0.05) * (root.maximum - root.minimum);
            root.sliderMoved(Services.Theme.clamp(root.value + step, root.minimum, root.maximum));
        }
    }
}
