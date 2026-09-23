import QtQuick
import "../services" as Services
Rectangle {
    id: root
    property real fraction: 0
    property bool animated: true
    color: Services.Theme.accentFg
    Rectangle {
        width: parent.width * Services.Theme.clamp01(root.fraction)
        height: parent.height
        color: Services.Theme.accent
        Behavior on width {
            enabled: root.animated
            NumberAnimation {
                duration: 120
            }
        }
    }
}
