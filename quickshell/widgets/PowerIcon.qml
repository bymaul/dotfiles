import QtQuick
import "../components"
import "../services" as Services
BarIcon {
    required property var bar
    anchors.verticalCenter: parent.verticalCenter
    glyph: "󰐥"
    tipText: "Power menu"
    tipAnchor: bar
    onClicked: bar.togglePower()
}
