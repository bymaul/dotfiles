import "../components"
BarIcon {
    required property var bar
    required property var clockSource
    anchors.verticalCenter: parent.verticalCenter
    glyph: Qt.formatDateTime(clockSource?.date ?? new Date(), "HH:mm")
    tipText: Qt.formatDateTime(clockSource?.date ?? new Date(), "dddd, d MMMM yyyy")
    tipAnchor: bar
    onClicked: bar.togglePopup("calendar")
}
