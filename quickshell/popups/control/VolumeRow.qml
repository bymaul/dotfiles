import QtQuick
import "../../components"
import "../../services" as Services

Rectangle {
    required property var popup
    width: parent.width
    height: Services.Theme.rowHeight
    color: popup.selectedIndex === popup.volumeIdx() ? Services.Theme.activeBg : Services.Theme.surface
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: {
            if (containsMouse)
                popup.selectIndex(popup.volumeIdx());
        }
    }
    Row {
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 10
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            text: popup.audioSink?.audio?.muted ? "󰝟" : "󰕾"
            color: Services.Theme.fg
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px14
            MouseArea {
                anchors.fill: parent
                onClicked: popup.toggleVolumeMute()
            }
        }
        SliderBar {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 80
            maximum: Services.Theme.volumeMax
            wheelStep: Services.Theme.volumeStep
            value: popup.audioSink?.audio?.volume ?? 0
            onSliderMoved: value => {
                const audio = popup.audioSink?.audio;
                if (audio)
                    audio.volume = value;
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            horizontalAlignment: Text.AlignRight
            text: Math.round((popup.audioSink?.audio?.volume ?? 0) * 100) + "%"
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px12
        }
    }
}
