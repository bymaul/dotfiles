import QtQuick
Tile {
    id: root
    columns: 2
    active: false
    available: true
    selected: false
    signal actionClicked
    onClicked: root.actionClicked()
}
