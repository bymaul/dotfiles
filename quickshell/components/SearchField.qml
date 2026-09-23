import QtQuick
import "../services" as Services
Rectangle {
    id: root
    property alias text: field.text
    property alias input: field
    property bool accentBorder: false
    property bool catchEscape: false
    readonly property bool hasFocus: field.activeFocus
    signal upPressed()
    signal downPressed()
    signal accepted()
    signal escapePressed()
    function forceFocus(): void {
        field.forceActiveFocus();
    }
    function releaseFocus(): void {
        field.focus = false;
    }
    width: parent.width
    height: Services.Theme.rowHeight
    color: Services.Theme.transparent
    border.width: 1
    border.color: root.accentBorder ? Services.Theme.accent : Services.Theme.border
    TextInput {
        id: field
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        verticalAlignment: TextInput.AlignVCenter
        color: Services.Theme.fg
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px13
        Keys.onUpPressed: root.upPressed()
        Keys.onDownPressed: root.downPressed()
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onEscapePressed: event => {
            if (!root.catchEscape)
                event.accepted = false;
            else
                root.escapePressed();
        }
    }
}
