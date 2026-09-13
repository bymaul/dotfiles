import QtQuick
import Quickshell
Item {
    id: root
    required property string rawIcon
    property int iconSize: 24
    anchors.verticalCenter: parent.verticalCenter
    readonly property bool hasIcon: rawIcon !== ""
    readonly property bool iconIsDirect: rawIcon.startsWith("image://") || rawIcon.startsWith("/") || rawIcon.startsWith("file://")
    readonly property string directSource: rawIcon.startsWith("file://") || rawIcon.startsWith("image://") ? rawIcon : "file://" + rawIcon
    readonly property string themeIcon: hasIcon && !iconIsDirect ? Quickshell.iconPath(rawIcon, true) : ""
    readonly property string resolvedSource: hasIcon && iconIsDirect ? directSource : themeIcon
    visible: resolvedSource !== ""
    width: iconSize
    height: iconSize
    Image {
        anchors.fill: parent
        source: root.resolvedSource
        sourceSize.width: root.iconSize
        sourceSize.height: root.iconSize
        fillMode: Image.PreserveAspectFit
    }
}
