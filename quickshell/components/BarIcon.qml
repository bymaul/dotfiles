import QtQuick
import Quickshell
import "../services" as Services
Item {
    id: root
    required property string glyph
    property color glyphColor: Services.Theme.fg
    property int pixelSize: Services.Theme.px13
    property string tipText: ""
    property var tipAnchor: null
    property bool showPointer: true
    property bool tipHover: false
    signal clicked
    implicitWidth: label.width
    implicitHeight: label.height
    width: label.width
    height: label.height
    function showTip(): void {
        if (root.tipText === "" || !root.tipAnchor || !root.tipHover)
            return;
        const target = root.tipAnchor.contentItem;
        if (!target)
            return;
        const pt = root.mapToItem(target, 0, root.height);
        tip.anchor.rect.x = Math.max(Services.Theme.popupMargin, pt.x + root.width / 2 - tip.width / 2);
        tip.anchor.rect.y = pt.y + 4;
        tip.visible = true;
    }
    function hideTip(): void {
        root.tipHover = false;
        tipTimer.stop();
        tip.visible = false;
    }
    function armTip(): void {
        root.tipHover = true;
        tipTimer.restart();
    }
    Text {
        id: label
        text: root.glyph
        color: root.glyphColor
        font.family: Services.Theme.font
        font.pixelSize: root.pixelSize
    }
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.showPointer ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: root.armTip()
        onExited: root.hideTip()
        onClicked: {
            root.hideTip();
            root.clicked();
        }
    }
    Timer {
        id: tipTimer
        interval: 400
        repeat: false
        onTriggered: root.showTip()
    }
    PopupWindow {
        id: tip
        visible: false
        grabFocus: false
        anchor.window: root.tipAnchor
        implicitWidth: tipLabel.implicitWidth + 16
        implicitHeight: tipLabel.implicitHeight + 12
        Rectangle {
            anchors.fill: parent
            color: Services.Theme.bg
            border.width: 1
            border.color: Services.Theme.border
            Text {
                id: tipLabel
                anchors.centerIn: parent
                text: root.tipText
                color: Services.Theme.fg
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px11
            }
        }
    }
}
