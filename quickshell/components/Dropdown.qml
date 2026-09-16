import QtQuick
import "../Palette.js" as Palette

Item {
    id: root
    required property var options
    required property string current
    property bool open: false
    property bool selected: false
    property int cursor: 0
    property bool openUp: false
    property bool enabled: true
    property int maxVisible: 6
    signal headerClicked()
    signal optionClicked(string value)
    width: parent.width
    height: Palette.rowHeight
    function menuHeight(): int {
        const n = Math.min(root.options.length, root.maxVisible);
        if (n <= 0)
            return 0;
        return n * Palette.rowHeight + (n - 1) * Palette.listSpacing + 8;
    }
    onCursorChanged: {
        if (root.open)
            optList.positionViewAtIndex(root.cursor, ListView.Contain);
    }
    onOpenChanged: {
        if (root.open)
            optList.positionViewAtIndex(root.cursor, ListView.Contain);
    }
    Rectangle {
        id: header
        width: parent.width
        height: Palette.rowHeight
        color: root.open ? Palette.activeBg : root.selected ? Palette.accent : headerHover.containsMouse ? Palette.hoverBg : Palette.surface
        Text {
            id: headerLabel
            anchors {
                left: parent.left
                leftMargin: 10
                right: chevron.left
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }
            verticalAlignment: Text.AlignVCenter
            text: root.current
            color: root.open ? Palette.fg : root.selected ? Palette.onAccent : Palette.fg
            font.family: Palette.font
            font.pixelSize: Palette.px12
            elide: Text.ElideRight
        }
        Text {
            id: chevron
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            visible: root.enabled
            width: 14
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: root.open ? "▴" : "▾"
            color: root.open ? Palette.dim : root.selected ? Palette.onAccent : Palette.dim
            font.family: Palette.font
            font.pixelSize: Palette.px12
        }
        MouseArea {
            id: headerHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (root.enabled)
                    root.headerClicked();
            }
        }
    }
    Rectangle {
        visible: root.open && root.enabled && root.options.length > 0
        width: parent.width
        height: root.menuHeight()
        y: root.openUp ? -(root.menuHeight() + Palette.listSpacing) : Palette.rowHeight + Palette.listSpacing
        z: 100
        color: Palette.bg
        border.width: 1
        border.color: Palette.border
        ListView {
            id: optList
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            spacing: Palette.listSpacing
            model: root.options
            currentIndex: root.cursor
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool isCurrent: modelData === root.current
                readonly property bool isCursor: index === root.cursor
                width: ListView.view.width
                height: Palette.rowHeight
                color: isCursor ? Palette.accent : optHover.containsMouse ? Palette.hoverBg : isCurrent ? Palette.activeBg : Palette.surface
                Text {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: Text.AlignVCenter
                    text: (parent.isCurrent ? "✓  " : "") + modelData
                    color: parent.isCursor ? Palette.onAccent : parent.isCurrent ? Palette.accent : optHover.containsMouse ? Palette.fg : Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: optHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.optionClicked(modelData)
                }
            }
        }
    }
}
