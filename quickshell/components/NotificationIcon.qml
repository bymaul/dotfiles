import QtQuick
import QtQuick.Effects
import Quickshell
Item {
    id: root
    required property var rawIcon
    property int iconSize: 24
    anchors.verticalCenter: parent.verticalCenter
    readonly property string iconStr: String(root.rawIcon ?? "")
    readonly property bool hasIcon: root.iconStr !== ""
    readonly property bool iconIsDirect: root.iconStr.startsWith("image://") || root.iconStr.startsWith("/") || root.iconStr.startsWith("file://")
    readonly property string directSource: root.iconStr.startsWith("file://") || root.iconStr.startsWith("image://") ? root.iconStr : "file://" + root.iconStr
    readonly property string themeIcon: hasIcon && !iconIsDirect ? Quickshell.iconPath(root.iconStr, true) : ""
    readonly property string resolvedSource: hasIcon && iconIsDirect ? directSource : themeIcon
    readonly property bool recolorable: !iconIsDirect && root.iconStr.endsWith("-symbolic")
    readonly property bool showIcon: root.resolvedSource !== ""
    visible: showIcon
    width: showIcon ? iconSize : 0
    height: iconSize
    Image {
        id: img
        anchors.fill: parent
        source: root.resolvedSource
        sourceSize.width: root.iconSize
        sourceSize.height: root.iconSize
        fillMode: Image.PreserveAspectFit
        cache: true
        asynchronous: true
        visible: !root.recolorable && root.resolvedSource !== ""
    }
    MultiEffect {
        anchors.fill: parent
        visible: root.recolorable && root.resolvedSource !== ""
        source: img
        brightness: 0.6
    }
}
