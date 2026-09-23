import QtQuick

// A SettingsRow whose control is a Dropdown, with the header/option
// wiring forwarded as signals. Replaces the copy-pasted
// SettingsRow + Dropdown blocks in settings-style popups.
SettingsRow {
    id: root
    property var options: []
    property string current: ""
    property bool dropEnabled: true
    property bool dropOpen: false
    property bool openUp: false
    property int cursor: 0
    signal headerClicked()
    signal optionHovered(int index)
    signal optionClicked(string value)
    value: ""
    Dropdown {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        options: root.options
        current: root.current
        enabled: root.dropEnabled
        open: root.dropOpen
        selected: root.selected
        cursor: root.cursor
        openUp: root.openUp
        onHeaderClicked: root.headerClicked()
        onOptionHovered: index => root.optionHovered(index)
        onOptionClicked: value => root.optionClicked(value)
    }
}
