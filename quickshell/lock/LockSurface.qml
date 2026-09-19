import QtQuick
import Quickshell
import "../Palette.js" as Palette
Item {
    id: root
    required property var context
    component Label: Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        font.family: Palette.font
        font.pixelSize: Palette.px12
    }
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    Rectangle {
        anchors.fill: parent
        color: Palette.bg
        Column {
            anchors.centerIn: parent
            width: 300
            spacing: 10
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Palette.fg
                font.family: Palette.font
                font.pixelSize: 64
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                color: Palette.dim
                font.family: Palette.font
                font.pixelSize: Palette.px14
            }
            Rectangle {
                width: parent.width
                height: Palette.rowHeight
                color: Palette.surface
                border.width: 1
                border.color: root.context.showFailure ? Palette.danger : Palette.border
                TextInput {
                    id: field
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Palette.fg
                    echoMode: TextInput.Password
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                    enabled: !root.context.unlockInProgress
                    onTextChanged: root.context.currentText = text
                    Keys.onReturnPressed: root.context.tryUnlock()
                    Keys.onEnterPressed: root.context.tryUnlock()
                    Keys.onEscapePressed: root.context.currentText = ""
                    Component.onCompleted: {
                        forceActiveFocus();
                        focusRetry.restart();
                    }
                    Timer {
                        id: focusRetry
                        interval: 200
                        repeat: true
                        onTriggered: {
                            if (!field.activeFocus && field.visible && field.enabled) {
                                field.forceActiveFocus();
                            } else {
                                focusRetry.stop();
                            }
                        }
                    }
                    Connections {
                        target: root.context
                        function onCurrentTextChanged() {
                            if (field.text !== root.context.currentText)
                                field.text = root.context.currentText;
                        }
                    }
                }
            }
            Label {
                visible: root.context.showFailure
                text: "Incorrect password"
                color: Palette.danger
            }
            Label {
                visible: root.context.authMessage !== ""
                text: root.context.authMessage
                color: Palette.warn
                wrapMode: Text.WordWrap
            }
            Label {
                text: root.context.unlockInProgress ? "Unlocking..." : "Enter password to unlock"
                color: Palette.dim
            }
        }
    }
}
