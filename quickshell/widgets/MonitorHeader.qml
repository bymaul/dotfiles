import QtQuick
import "../services" as Services

Item {
    id: root
    required property string screenName
    anchors.fill: parent
    WindowTitle {
        screenName: root.screenName
        leftItem: Services.Theme.workspacesOnLeft ? workspaces : null
    }
    Workspaces {
        id: workspaces
        screenName: root.screenName
    }
}
