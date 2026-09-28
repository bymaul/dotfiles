import QtQuick
import "../services" as Services
import "../components"
BarIcon {
    required property var bar
    visible: Services.Modes.dndActive
    glyph: ""
    glyphColor: Services.Theme.accent
    tipText: "Do not disturb (on)"
    tipAnchor: bar
    onClicked: Services.Modes.toggleDnd()
}
