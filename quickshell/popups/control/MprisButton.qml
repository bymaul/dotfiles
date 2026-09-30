import QtQuick
import "../../services" as Services

Text {
    id: root
    required property var popup
    required property int col
    property bool canUse: true
    property int btnWidth: 20
    property int px: Services.Theme.px14
    readonly property bool highlighted: root.popup.selectedKind() === "mpris" && root.popup.mprisCol === root.col

    anchors.verticalCenter: parent.verticalCenter
    width: root.btnWidth
    horizontalAlignment: Text.AlignHCenter
    opacity: root.canUse ? 1 : 0.35
    color: root.highlighted ? Services.Theme.accentFg : Services.Theme.fg
    font.family: Services.Theme.font
    font.pixelSize: root.px
    Rectangle {
        anchors.centerIn: parent
        width: root.btnWidth === 20 ? 24 : root.btnWidth
        height: 24
        visible: root.highlighted
        color: Services.Theme.accent
        z: -1
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (containsMouse)
                root.popup.selectMpris(root.col);
        }
        onClicked: root.popup.activateMpris(root.col)
    }
}
