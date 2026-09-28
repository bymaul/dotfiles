import QtQuick

// Per-monitor workspaces + window title pair shared by Bar and SlimBar.
Item {
    id: root
    required property string screenName
    anchors.fill: parent
    WindowTitle {
        screenName: root.screenName
    }
    Workspaces {
        screenName: root.screenName
    }
}
