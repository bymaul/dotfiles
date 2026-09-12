import QtQuick
import Quickshell

// image:// URL, file path, or theme name; invisible when empty so
// Row layouts skip it.
Item {
    id: notifIcon

    required property string rawIcon
    property int iconSize: 24

    anchors.verticalCenter: parent.verticalCenter

    readonly property bool hasIcon: rawIcon !== ""
    readonly property bool iconIsDirect: rawIcon.startsWith("image://") || rawIcon.startsWith("/") || rawIcon.startsWith("file://")
    readonly property string directSource: rawIcon.startsWith("file://") || rawIcon.startsWith("image://") ? rawIcon : "file://" + rawIcon
    // iconPath's check variant returns "" instead of a broken image.
    readonly property string themeIcon: hasIcon && !iconIsDirect ? Quickshell.iconPath(rawIcon, true) : ""

    visible: (hasIcon && iconIsDirect) || themeIcon !== ""

    width: iconSize
    height: iconSize

    Image {
        anchors.fill: parent

        visible: notifIcon.hasIcon && notifIcon.iconIsDirect

        source: notifIcon.directSource

        sourceSize.width: notifIcon.iconSize
        sourceSize.height: notifIcon.iconSize

        fillMode: Image.PreserveAspectFit
    }

    Image {
        anchors.fill: parent

        visible: notifIcon.themeIcon !== ""

        source: notifIcon.themeIcon

        sourceSize.width: notifIcon.iconSize
        sourceSize.height: notifIcon.iconSize

        fillMode: Image.PreserveAspectFit
    }
}
