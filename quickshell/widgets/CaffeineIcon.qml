import QtQuick
import "../services" as Services
import "../components"
BarIcon {
    visible: Services.Modes.caffeineActive
    glyph: "󰅶"
    glyphColor: Services.Theme.accent
    onClicked: Services.Modes.toggleCaffeine()
}
