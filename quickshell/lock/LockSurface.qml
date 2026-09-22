import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../services" as Services
Item {
    id: root
    required property var context
    property var ownScreen: null
    readonly property string ownName: ownScreen && ownScreen.name ? String(ownScreen.name) : ""
    readonly property string focusedName: Hyprland.focusedMonitor?.name ?? ""
    readonly property bool isFocusScreen: ownName === "" || focusedName === "" || ownName === focusedName
    readonly property bool maySteal: context.activeSurface === "" || (ownName !== "" && context.activeSurface === ownName)
    component Label: Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        font.family: Services.Theme.font
        font.pixelSize: Services.Theme.px12
    }
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    Rectangle {
        anchors.fill: parent
        color: Services.Theme.bg
        Column {
            anchors.centerIn: parent
            width: 300
            spacing: 10
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Services.Theme.fg
                font.family: Services.Theme.font
                font.pixelSize: 64
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px14
            }
            Rectangle {
                width: parent.width
                height: Services.Theme.rowHeight
                color: Services.Theme.surface
                border.width: 1
                border.color: root.context.showFailure ? Services.Theme.danger : Services.Theme.border
                TextInput {
                    id: field
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Services.Theme.fg
                    echoMode: TextInput.Password
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    enabled: !root.context.unlockInProgress
                    onTextChanged: root.context.currentText = text
                    onActiveFocusChanged: {
                        if (activeFocus && root.ownName !== "")
                            root.context.activeSurface = root.ownName;
                    }
                    Keys.onReturnPressed: root.context.tryUnlock()
                    Keys.onEnterPressed: root.context.tryUnlock()
                    Keys.onEscapePressed: root.context.currentText = ""
                    function claimFocus(): void {
                        if (!field.visible || !field.enabled)
                            return;
                        field.forceActiveFocus();
                        if (field.activeFocus && root.ownName !== "")
                            root.context.activeSurface = root.ownName;
                    }
                    Component.onCompleted: {
                        if (root.isFocusScreen) {
                            field.claimFocus();
                            if (!field.activeFocus)
                                focusRetry.restart();
                        } else {
                            claimWaiter.restart();
                        }
                    }
                    Timer {
                        id: claimWaiter
                        interval: 500
                        repeat: false
                        onTriggered: {
                            if (root.context.activeSurface === "" && !field.activeFocus) {
                                field.claimFocus();
                                if (!field.activeFocus)
                                    focusRetry.restart();
                            }
                        }
                    }
                    Timer {
                        id: focusRetry
                        interval: 200
                        repeat: true
                        onTriggered: {
                            if (!root.maySteal) {
                                focusRetry.stop();
                                return;
                            }
                            if (!field.activeFocus && field.visible && field.enabled) {
                                field.forceActiveFocus();
                                if (field.activeFocus && root.ownName !== "")
                                    root.context.activeSurface = root.ownName;
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
                color: Services.Theme.danger
            }
            Label {
                visible: root.context.authMessage !== ""
                text: root.context.authMessage
                color: Services.Theme.warn
                wrapMode: Text.WordWrap
            }
            Label {
                text: root.context.unlockInProgress ? "Unlocking..." : "Enter password to unlock"
                color: Services.Theme.dim
            }
        }
    }
}
