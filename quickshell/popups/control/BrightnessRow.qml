import QtQuick
import "../../components"
import "../../services" as Services

Rectangle {
    required property var popup
    visible: Services.Media.brightnessAvailable
    width: parent.width
    height: visible ? Services.Theme.rowHeight : 0
    color: popup.selectedIndex === 0 ? Services.Theme.activeBg : Services.Theme.surface
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: {
            if (containsMouse)
                popup.selectIndex(0);
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
            text: "󰃟"
            color: Services.Theme.fg
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px14
        }
        SliderBar {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 80
            value: Services.Media.brightness / 100
            onSliderMoved: value => Services.Media.setBrightness(value * 100, true)
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            horizontalAlignment: Text.AlignRight
            text: Math.round(Services.Media.brightness) + "%"
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px12
        }
    }
}
