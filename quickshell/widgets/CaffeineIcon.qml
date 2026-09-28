import QtQuick
import "../services" as Services
import "../components"
BarIcon {
    required property var bar
    visible: Services.Modes.caffeineActive
    glyph: "󰅶"
    glyphColor: Services.Theme.accent
    tipText: "Caffeine (on)"
    tipAnchor: bar
    onClicked: Services.Modes.toggleCaffeine()
}
