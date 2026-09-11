import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../Palette.js" as Palette

Item {
    id: volumeControl

    required property var bar

    width: volumeText.width
    height: volumeText.height

    property var sink: Pipewire.defaultAudioSink

    // IMPORTANT:
    // audio.volume and audio.muted require
    // the node to be bound.
    PwObjectTracker {
        objects: [volumeControl.sink]
    }

    Text {
        id: volumeText

        property real level:
            volumeControl.sink?.audio?.volume ?? 0

        property bool muted:
            volumeControl.sink?.audio?.muted ?? false

        text: {
            if (muted)
                return "󰝟"

            if (level <= 0.01)
                return "󰖀"

            if (level < 0.5)
                return "󰕾"

            return "󰕾"
        }

        color: volumeText.level > 1 ? Palette.warn : Palette.fg

        font.family: Palette.font
        font.pixelSize: Palette.px13

        MouseArea {
            anchors.fill: parent

            onClicked: bar.toggleControl()

            onWheel: event => {
                const audio =
                    volumeControl.sink?.audio

                if (!audio)
                    return

                const step = 0.05

                if (event.angleDelta.y > 0) {
                    audio.volume =
                        Math.min(
                            1.5,
                            audio.volume + step
                        )
                } else {
                    audio.volume =
                        Math.max(
                            0.0,
                            audio.volume - step
                        )
                }
            }
        }
    }
}