import QtQuick
import Quickshell.Networking
import "../Palette.js" as Palette

Item {
    required property var bar

    width: wifiIcon.width
    height: wifiIcon.height

    Text {
        id: wifiIcon

        property bool connected: bar.connectedWifi !== null

        text: {
            if (!Networking.wifiEnabled)
                return "󰤭";

            if (!connected)
                return "󰤯";

            return "󰤨";
        }

        color: {
            if (!Networking.wifiEnabled || !connected)
                return Palette.dim;

            return Palette.fg;
        }

        font.family: Palette.font
        font.pixelSize: Palette.px13

        MouseArea {
            anchors.fill: parent

            onClicked: bar.toggleControl()
        }
    }
}
