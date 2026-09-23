import QtQuick
import "../services" as Services

// Shared notification action pills, used by toasts and history cards.
// focusedIndex highlights one pill (-1 for none); hovered/picked carry
// the action index and object to the owner for activation.
Flow {
    id: root
    property var actions: []
    property int focusedIndex: -1
    signal hovered(int index)
    signal picked(var action)
    visible: (root.actions ?? []).length > 0
    spacing: 6
    Repeater {
        model: root.actions
        delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property bool focused: index === root.focusedIndex
            width: actionLabel.width + 16
            height: 24
            color: focused ? Services.Theme.accent : actionArea.containsMouse ? Services.Theme.hoverBg : Services.Theme.surface
            Text {
                id: actionLabel
                anchors.centerIn: parent
                text: modelData.text
                color: parent.focused ? Services.Theme.accentFg : Services.Theme.fg
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
            }
            MouseArea {
                id: actionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: {
                    if (containsMouse)
                        root.hovered(index);
                }
                onClicked: mouse => {
                    mouse.accepted = true;
                    root.picked(modelData);
                }
            }
        }
    }
}
