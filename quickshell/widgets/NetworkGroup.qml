import QtQuick

Item {
    id: networkGroup

    required property var bar

    width: icons.width
    height: icons.height

    property alias volumeControl: groupVolume

    Row {
        id: icons

        spacing: 12

        WifiIcon { bar: networkGroup.bar }
        BluetoothIcon { bar: networkGroup.bar }
        VolumeIcon {
            id: groupVolume

            bar: networkGroup.bar
        }
    }

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor

        onClicked: bar.toggleControl()
    }
}