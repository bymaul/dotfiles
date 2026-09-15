import QtQuick
import "../services" as Services
import "../components"
import "../Palette.js" as Palette
Item {
    visible: Services.Modes.dndActive
    implicitWidth: icon.width
    implicitHeight: icon.height
    width: icon.width
    height: icon.height
    BarIcon {
        id: icon
        glyph: ""
        glyphColor: Palette.accent
        onClicked: Services.Modes.toggleDnd()
    }
}
