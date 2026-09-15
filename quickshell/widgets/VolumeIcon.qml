import QtQuick
import Quickshell.Services.Pipewire
import "../components"
import "../Palette.js" as Palette
Item {
    id: root
    required property var bar
    implicitWidth: icon.width
    implicitHeight: icon.height
    width: icon.width
    height: icon.height
    property var sink: Pipewire.defaultAudioSink
    PwObjectTracker {
        objects: [root.sink]
    }
    readonly property real level: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false
    BarIcon {
        id: icon
        glyph: {
            if (root.muted)
                return "󰝟";
            if (root.level <= 0.3)
                return "󰖀";
            if (root.level < 1.0)
                return "󰕾";
            return "󰝝";
        }
        glyphColor: root.level > 1 ? Palette.warn : Palette.fg
        onClicked: bar.toggleControl()
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onWheel: event => {
            const audio = root.sink?.audio;
            if (!audio)
                return;
            audio.volume = Palette.clamp(audio.volume + (event.angleDelta.y > 0 ? Palette.volumeStep : -Palette.volumeStep), 0, Palette.volumeMax);
        }
    }
}
