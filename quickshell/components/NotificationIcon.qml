import QtQuick
import Quickshell

// Shared notification icon (ToastCard + history rows): a ready-made
// image:// URL, a file path, or a bare theme name. Only bare names
// go through theme lookup; URLs load directly. Invisible when there
// is nothing to show, so Row layouts skip it exactly as before.
Item {
    id: notifIcon

    required property string rawIcon
    property int iconSize: 24

    anchors.verticalCenter: parent.verticalCenter

    readonly property bool hasIcon: rawIcon !== ""
    readonly property bool iconIsDirect: rawIcon.startsWith("image://") ||
        rawIcon.startsWith("/") || rawIcon.startsWith("file://")
    readonly property string directSource: rawIcon.startsWith("file://") ||
        rawIcon.startsWith("image://")
        ? rawIcon : "file://" + rawIcon
    // Theme names resolve through the platform theme; the check
    // variant yields "" instead of a missing-texture square.
    readonly property string themeIcon: hasIcon && !iconIsDirect
        ? Quickshell.iconPath(rawIcon, true) : ""

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
