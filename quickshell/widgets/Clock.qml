import "../components"
BarIcon {
    required property var bar
    required property var clockSource
    anchors.verticalCenter: parent.verticalCenter
    glyph: Qt.formatDateTime(clockSource?.date ?? new Date(), "ddd dd MMM HH:mm")
    onClicked: bar.togglePopup("calendar")
}
