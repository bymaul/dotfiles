import QtQuick
Tile {
    id: root
    property bool enabled: true
    available: root.enabled
    columns: 3
    signal tileClicked
    onClicked: root.tileClicked()
}
