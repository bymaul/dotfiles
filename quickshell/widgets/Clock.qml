import QtQuick
import "../Palette.js" as Palette

Item {
    required property var bar
    required property var clockSource

    anchors.centerIn: parent

    width: clockText.width + 20
    height: 34

    Text {
        id: clockText

        anchors.centerIn: parent

        text: {
            const d = clockSource ? clockSource.date : null;

            return d ? Qt.formatDateTime(d, "HH:mm") : "";
        }

        color: Palette.fg

        font.family: Palette.font
        font.pixelSize: Palette.px13
    }

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor

        onClicked: {
            bar.toggleCalendar();
        }
    }
}
