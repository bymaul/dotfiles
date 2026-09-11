import QtQuick

Item {
    id: systemGroup

    required property var bar

    width: content.width
    height: content.height

    property alias volumeControl: networkGroup.volumeControl

    Row {
        id: content

        spacing: 12

        CaffeineIcon {}
        DndIcon {}
        MemCpu { bar: systemGroup.bar }
        NetworkGroup {
            id: networkGroup

            bar: systemGroup.bar
        }
    }
}