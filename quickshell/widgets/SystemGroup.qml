import QtQuick
import "../Palette.js" as Palette
Item {
    id: root
    required property var bar
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.width
    implicitHeight: row.height
    width: row.width
    height: row.height
    Row {
        id: row
        spacing: Palette.groupSpacing
        CaffeineIcon {}
        DndIcon {}
        MemCpu {
            bar: root.bar
        }
        NetworkGroup {
            bar: root.bar
        }
    }
}
