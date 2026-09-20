import QtQuick
import "../services" as Services
import "../components"
BarIcon {
    visible: Services.Modes.dndActive
    glyph: ""
    glyphColor: Services.Theme.accent
    onClicked: Services.Modes.toggleDnd()
}
