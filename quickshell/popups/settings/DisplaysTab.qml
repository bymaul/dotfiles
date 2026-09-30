import QtQuick
import "../../components"
import "../../services" as Services
import "../../services/SettingsUtil.js" as SettingsUtil

Column {
    id: root
    required property var popup

    visible: popup.tab === 2
    width: parent.width
    spacing: Services.Theme.popupSpacing
    DropdownRow {
        title: "Main display"
        selected: popup.tab === 2 && popup.selectedIndex === 0
        onHovered: {
            if (!popup.anyDropOpen())
                popup.selectedIndex = 0;
        }
        z: popup.openMainDrop ? 100 : 0
        options: popup.mainOptions()
        current: Services.Settings.mainMonitor
        dropEnabled: popup.enabledCount > 1
        dropOpen: popup.openMainDrop
        cursor: popup.dropCursor
        onHeaderClicked: {
            popup.selectedIndex = 0;
            popup.toggleMainDrop();
        }
        onOptionHovered: index => popup.dropCursor = index
        onOptionClicked: value => {
            popup.selectedIndex = 0;
            Services.Settings.setMainMonitor(value);
            popup.closeDrop();
        }
    }
    Text {
        visible: popup.monCount === 0
        width: parent.width
        height: 30
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: "No monitors found. Is hyprctl reachable?"
        color: Services.Theme.dim
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px10
    }
    Column {
        id: monColumn
        visible: popup.monCount > 0
        width: parent.width
        spacing: Services.Theme.popupSpacing
        z: popup.openMonRes !== "" || popup.openMonPos !== "" ? 50 : 0
        Repeater {
            model: Services.Settings.monitors
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property string monName: String(modelData.name ?? "")
                readonly property bool monOn: Services.Settings.monitorEnabled(monName)
                width: parent.width
                height: popup.monBlockH
                color: Services.Theme.transparent
                border.width: 1
                border.color: Services.Theme.border
                z: popup.openMonRes === monName || popup.openMonPos === monName ? 100 : 0
                Column {
                    anchors.fill: parent
                    anchors.margins: popup.monCardPad
                    spacing: Services.Theme.listSpacing
                    Text {
                        width: parent.width
                        height: popup.monHeaderH
                        verticalAlignment: Text.AlignVCenter
                        text: Services.Settings.monitorSummary(monName)
                        color: monOn ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                        elide: Text.ElideRight
                    }
                    SettingsRow {
                        selected: popup.tab === 2 && popup.selectedIndex === popup.monFirst + index * popup.monRows + 0
                        onHovered: {
                            if (!popup.anyDropOpen())
                                popup.selectedIndex = popup.monFirst + index * popup.monRows + 0;
                        }
                        title: "Enabled"
                        value: monOn ? "On" : "Off"
                        SettingsSwitch {
                            on: monOn
                            disabled: !Services.Settings.canDisableMonitor(monName)
                            onToggled: {
                                popup.beginMonitorChange();
                                Services.Settings.setMonitorEnabled(monName, !Services.Settings.monitorEnabled(monName))
                            }
                        }
                    }
                    SettingsRow {
                        opacity: monOn ? 1 : 0.45
                        selected: popup.tab === 2 && popup.selectedIndex === popup.monFirst + index * popup.monRows + 1
                        onHovered: {
                            if (!popup.anyDropOpen())
                                popup.selectedIndex = popup.monFirst + index * popup.monRows + 1;
                        }
                        title: "Scale"
                        value: "x" + Services.Settings.monitorScale(monName).toFixed(2).replace(/0$/, "")
                        SliderBar {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            minimum: 0.5
                            maximum: 3
                            value: Services.Settings.monitorScale(monName)
                            onSliderMoved: value => {
                                popup.beginMonitorChange();
                                Services.Settings.setMonitorScale(monName, Math.round(value * 20) / 20)
                            }
                        }
                    }
                    DropdownRow {
                        opacity: monOn ? 1 : 0.45
                        title: "Resolution"
                        selected: popup.tab === 2 && popup.selectedIndex === popup.monFirst + index * popup.monRows + 2
                        onHovered: {
                            if (!popup.anyDropOpen())
                                popup.selectedIndex = popup.monFirst + index * popup.monRows + 2;
                        }
                        z: popup.openMonRes === monName ? 100 : 0
                        options: Services.Settings.monitorModes(monName)
                        current: Services.Settings.monitorRes(monName)
                        dropOpen: popup.openMonRes === monName
                        cursor: popup.dropCursor
                        openUp: index === popup.monCount - 1
                        onHeaderClicked: {
                            popup.selectedIndex = popup.monFirst + index * popup.monRows + 2;
                            popup.toggleMonDrop(monName);
                        }
                        onOptionHovered: optIdx => popup.dropCursor = optIdx
                        onOptionClicked: value => {
                            popup.selectedIndex = popup.monFirst + index * popup.monRows + 2;
                            popup.commitMonRes(monName, value);
                        }
                    }
                    DropdownRow {
                        opacity: monOn ? 1 : 0.45
                        title: "Position"
                        selected: popup.tab === 2 && popup.selectedIndex === popup.monFirst + index * popup.monRows + 3
                        onHovered: {
                            if (!popup.anyDropOpen())
                                popup.selectedIndex = popup.monFirst + index * popup.monRows + 3;
                        }
                        z: popup.openMonPos === monName ? 100 : 0
                        options: SettingsUtil.monitorPosOptions()
                        current: Services.Settings.monitorPos(monName)
                        dropOpen: popup.openMonPos === monName
                        cursor: popup.dropCursor
                        openUp: index === popup.monCount - 1
                        onHeaderClicked: {
                            popup.selectedIndex = popup.monFirst + index * popup.monRows + 3;
                            popup.toggleMonPosDrop(monName);
                        }
                        onOptionHovered: optIdx => popup.dropCursor = optIdx
                        onOptionClicked: value => {
                            popup.selectedIndex = popup.monFirst + index * popup.monRows + 3;
                            popup.commitMonPos(monName, value);
                        }
                    }
                }
            }
        }
    }
    PopupButton {
        label: "Re-detect displays"
        columns: 1
        selected: popup.tab === 2 && popup.selectedIndex === popup.monLastIndex()
        onHovered: {
            if (!popup.anyDropOpen())
                popup.selectedIndex = popup.monLastIndex();
        }
        onClicked: {
            popup.selectedIndex = popup.monLastIndex();
            Services.Settings.refreshMonitors(true);
        }
    }
    Text {
        width: parent.width
        height: 14
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: Services.Settings.lastApplyMsg
        color: Services.Theme.dim
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px10
    }
}
