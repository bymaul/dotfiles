import QtQuick
import "../services" as Services
Item {
    id: root
    required property var bar
    implicitWidth: row.width
    implicitHeight: row.height
    width: row.width
    height: row.height
    Row {
        id: row
        spacing: Services.Theme.groupSpacing
        WifiIcon {
            bar: root.bar
        }
        BluetoothIcon {
            bar: root.bar
        }
        VolumeIcon {
            bar: root.bar
        }
    }
}
