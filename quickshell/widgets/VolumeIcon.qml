import QtQuick
import Quickshell.Services.Pipewire
import "../components"
import "../services" as Services
BarIcon {
    id: root
    required property var bar
    property var sink: Pipewire.defaultAudioSink
    PwObjectTracker {
        objects: [root.sink]
    }
    readonly property real level: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false
    glyph: {
        if (root.muted)
            return "󰝟";
        if (root.level <= 0.3)
            return "󰖀";
        if (root.level < 1.0)
            return "󰕾";
        return "󰝝";
    }
    glyphColor: root.level > 1 ? Services.Theme.warn : Services.Theme.fg
    tipText: root.muted ? "Muted" : "Volume " + Math.round(root.level * 100) + "%"
    tipAnchor: root.bar
    onClicked: bar.toggleControl()
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.armTip()
        onExited: root.hideTip()
        onWheel: event => {
            Services.Media.adjustVolume(event.angleDelta.y > 0 ? Services.Theme.volumeStep : -Services.Theme.volumeStep, true);
        }
    }
}
