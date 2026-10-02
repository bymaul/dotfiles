import QtQuick

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
