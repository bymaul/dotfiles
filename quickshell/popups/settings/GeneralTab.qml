import QtQuick
import "../../components"
import "../../services" as Services

Column {
    id: root
    required property var popup
    property alias wallList: wallList

    visible: popup.tab === 0
    width: parent.width
    spacing: Services.Theme.popupSpacing
    Text {
        width: parent.width
        height: popup.sectionH
        verticalAlignment: Text.AlignVCenter
        text: Services.Settings.wallpapers.length > 0 ? "Wallpaper  ·  " + Services.Settings.wallpapers.length : "Wallpaper"
        color: Services.Theme.dim
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px11
    }
    Column {
        width: parent.width
        spacing: Services.Theme.listSpacing
        GridView {
            id: wallList
            width: parent.width
            height: popup.wpListH
            visible: popup.wpCount > 0
            clip: true
            flow: GridView.FlowLeftToRight
            cellWidth: Math.max(1, Math.floor(width / popup.wpCols))
            cellHeight: popup.wpCellH
            cacheBuffer: popup.wpCellH * 3
            model: Services.Settings.wallpapers
            onCountChanged: popup.syncWallCursor()
            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool current: modelData === Services.Settings.wallpaperOverride
                readonly property bool selected: wallList.currentIndex === index
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    color: Services.Theme.surface
                    border.width: cell.selected ? 2 : cell.current || thumbHover.containsMouse ? 1 : 0
                    border.color: cell.selected || cell.current ? Services.Theme.accent : Services.Theme.fg
                    clip: true
                    Image {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            bottom: nameLabel.top
                            topMargin: 4
                            leftMargin: 4
                            rightMargin: 4
                            bottomMargin: 4
                        }
                        source: "file://" + cell.modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        mipmap: true
                        sourceSize.width: 256
                    }
                    Text {
                        id: nameLabel
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: 6
                            rightMargin: 6
                            bottomMargin: 3
                        }
                        height: 17
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: (cell.current ? "✓ " : "") + String(cell.modelData).split("/").pop()
                        color: cell.selected ? Services.Theme.fg : cell.current ? Services.Theme.accent : thumbHover.containsMouse ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px10
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        id: thumbHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse) {
                                wallList.currentIndex = cell.index;
                                popup.selectedIndex = cell.index;
                            }
                        }
                        onClicked: {
                            wallList.currentIndex = cell.index;
                            popup.selectedIndex = cell.index;
                            Services.Settings.setWallpaper(cell.modelData);
                        }
                    }
                }
            }
        }
        Text {
            width: parent.width
            visible: popup.wpCount === 0
            wrapMode: Text.WordWrap
            text: "Add images to ~/dotfiles/wallpapers or ~/Pictures/Wallpapers"
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px12
        }
    }
    Text {
        width: parent.width
        height: popup.sectionH
        verticalAlignment: Text.AlignVCenter
        text: "Mouse & touchpad"
        color: Services.Theme.dim
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px11
    }
    Column {
        width: parent.width
        spacing: Services.Theme.listSpacing
        SettingsRow {
            title: "Sensitivity"
            value: Services.Settings.sensitivity.toFixed(1)
            selected: popup.tab === 0 && popup.selectedIndex === popup.wpRows + 0
            onHovered: popup.selectedIndex = popup.wpRows + 0
            SliderBar {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                minimum: -1
                maximum: 1
                value: Services.Settings.sensitivity
                onSliderMoved: value => Services.Settings.setSensitivity(value)
            }
        }
        SettingsRow {
            title: "Touchpad scroll"
            value: Services.Settings.touchScroll.toFixed(1)
            selected: popup.tab === 0 && popup.selectedIndex === popup.wpRows + 1
            onHovered: popup.selectedIndex = popup.wpRows + 1
            SliderBar {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                minimum: 0.1
                maximum: 2
                value: Services.Settings.touchScroll
                onSliderMoved: value => Services.Settings.setTouchScroll(value)
            }
        }
        SettingsRow {
            title: "Natural scroll"
            value: Services.Settings.naturalScroll ? "On" : "Off"
            selected: popup.tab === 0 && popup.selectedIndex === popup.wpRows + 2
            onHovered: popup.selectedIndex = popup.wpRows + 2
            SettingsSwitch {
                on: Services.Settings.naturalScroll
                onToggled: Services.Settings.setNaturalScroll(!Services.Settings.naturalScroll)
            }
        }
    }
}
