import QtQuick
import Quickshell
import "../Palette.js" as Palette

// Content of one lock surface (WlSessionLock instantiates one per
// screen). Password state lives in the shared context so all
// monitors stay in sync.
Item {
    id: root

    required property var context

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

                radius: 0

                color: Palette.surface
                border.width: 1
                border.color: root.context.showFailure ? Palette.danger : Palette.border

                TextInput {
                    id: passwordBox

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

                    Component.onCompleted: forceActiveFocus()

                    Connections {
                        target: root.context

                        function onCurrentTextChanged() {
                            if (passwordBox.text !== root.context.currentText)
                                passwordBox.text = root.context.currentText;
                        }
                    }
                }
            }

            Text {
                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                visible: root.context.showFailure

                text: "Incorrect password"

                color: Palette.danger

                font.family: Palette.font
                font.pixelSize: Palette.px12
            }

            Text {
                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                visible: root.context.authMessage !== ""

                text: root.context.authMessage

                color: Palette.warn

                font.family: Palette.font
                font.pixelSize: Palette.px12

                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                text: root.context.unlockInProgress ? "Unlocking..." : "Enter password to unlock"

                color: Palette.dim

                font.family: Palette.font
                font.pixelSize: Palette.px12
            }
        }
    }
}
