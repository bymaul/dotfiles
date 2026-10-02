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
        text: "Wallpaper"
        color: Services.Theme.dim
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px11
    }
    Column {
        width: parent.width
        spacing: Services.Theme.listSpacing
        ListView {
            id: wallList
            width: parent.width
            height: popup.wpListH
            clip: true
            spacing: Services.Theme.listSpacing
            model: Services.Settings.wallpapers
            onCountChanged: popup.syncWallCursor()
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool current: modelData === Services.Settings.wallpaperOverride
                readonly property bool selected: wallList.currentIndex === index
                width: ListView.view.width
                height: Services.Theme.listRowHeight
                color: selected ? Services.Theme.activeBg : current ? Services.Theme.activeBg : rowHover.containsMouse ? Services.Theme.hoverBg : Services.Theme.transparent
                border.width: (!selected && current) ? 1 : 0
                border.color: Services.Theme.accent
                Text {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: Text.AlignVCenter
                    text: (parent.current ? "✓  " : "") + String(modelData).split("/").pop()
                    color: parent.selected ? Services.Theme.fg : parent.current ? Services.Theme.accent : rowHover.containsMouse ? Services.Theme.fg : Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: {
                        if (containsMouse) {
                            wallList.currentIndex = index;
                            popup.selectedIndex = index;
                        }
                    }
                    onClicked: {
                        wallList.currentIndex = index;
                        popup.selectedIndex = index;
                        Services.Settings.setWallpaper(modelData);
                    }
                }
            }
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
