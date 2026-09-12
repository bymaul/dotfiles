import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../Palette.js" as Palette

BasePopup {
    id: clipboardPopup

    anchorMode: "center"

    implicitWidth: Palette.popupWidth
    implicitHeight: 16 + titleText.implicitHeight + Palette.rowHeight +
        Palette.popupSpacing * 3 +
        (10 * Palette.rowHeight + 9 * 4) + hintText.implicitHeight

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (clipboardPopup.wipeConfirm)
                clipboardPopup.wipeConfirm = false
            else
                bar.closePopups()
        }
    }

    Shortcut {
        sequence: "j"
        enabled: clipboardPopup.visible
        onActivated: clipboardPopup.stepSelection(1)
    }
    Shortcut {
        sequence: "k"
        enabled: clipboardPopup.visible
        onActivated: clipboardPopup.stepSelection(-1)
    }
    Shortcut {
        sequence: "Return"
        enabled: clipboardPopup.visible
        onActivated: clipboardPopup.confirm()
    }
    Shortcut {
        sequence: "Enter"
        enabled: clipboardPopup.visible
        onActivated: clipboardPopup.confirm()
    }
    Shortcut {
        sequence: "Space"
        enabled: clipboardPopup.visible
        onActivated: clipboardPopup.confirm()
    }
    Shortcut {
        sequence: "d"
        enabled: clipboardPopup.visible
        onActivated: clipboardPopup.deleteSelected()
    }
    Shortcut {
        sequence: "Shift+D"
        enabled: clipboardPopup.visible
        onActivated: clipboardPopup.requestWipe()
    }
    Shortcut {
        sequence: "h"
        enabled: clipboardPopup.visible && clipboardPopup.wipeConfirm
        onActivated: clipboardPopup.wipeChoice = 0
    }
    Shortcut {
        sequence: "l"
        enabled: clipboardPopup.visible && clipboardPopup.wipeConfirm
        onActivated: clipboardPopup.wipeChoice = 1
    }

    property var allEntries: []
    property int pendingIndex: 0
    property var deleteQueue: []

    property string activeAddress: ""
    property string activeClass: ""
    property bool wipeConfirm: false
    property int wipeChoice: 1

    onVisibleChanged: {
        if (visible)
            clipboardPopup.reset()
    }

    function reset(): void {
        activeAddress = ""
        activeClass = ""
        pendingIndex = 0
        deleteQueue = []
        wipeConfirm = false
        wipeChoice = 1
        focusProbe.running = true
        listProbe.running = true
    }

    function parseHistory(text: string): void {
        const out = []

        for (const line of text.split("\n")) {
            if (line.trim() === "")
                continue

            const tab = line.indexOf("\t")

            if (tab <= 0)
                continue

            out.push({
                line: line,
                id: line.slice(0, tab),
                preview: line.slice(tab + 1)
            })
        }

        clipboardPopup.allEntries = out

        if (out.length > 0) {
            list.currentIndex =
                Math.min(clipboardPopup.pendingIndex, out.length - 1)
            list.positionViewAtIndex(list.currentIndex, ListView.Contain)
        } else {
            list.currentIndex = -1
        }
    }

    function stepSelection(dir: int): void {
        clipboardPopup.wipeConfirm = false

        if (list.count === 0)
            return

        list.currentIndex = Math.max(0,
            Math.min(list.count - 1, list.currentIndex + dir))
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }

    function confirm(): void {
        if (clipboardPopup.wipeConfirm)
            clipboardPopup.confirmWipe()
        else
            clipboardPopup.pasteSelected()
    }

    function pasteSelected(): void {
        const entry = clipboardPopup.allEntries[list.currentIndex]

        if (!entry)
            return

        clipboardPopup.copySelection(entry)
    }

    function deleteSelected(): void {
        const entry = clipboardPopup.allEntries[list.currentIndex]

        if (!entry)
            return

        clipboardPopup.deleteEntry(entry)
    }

    function deleteEntry(entry: var): void {
        clipboardPopup.pendingIndex = Math.max(0, list.currentIndex)
        clipboardPopup.wipeConfirm = false
        clipboardPopup.deleteQueue.push(entry.line)
        clipboardPopup.runNextDelete()
    }

    function runNextDelete(): void {
        if (deleteProbe.running || clipboardPopup.deleteQueue.length === 0)
            return

        deleteProbe.command = [
            "sh",
            "-c",
            'printf "%s\\n" "$1" | cliphist delete',
            "qs",
            clipboardPopup.deleteQueue[0]
        ]
        deleteProbe.running = true
    }

    function requestWipe(): void {
        clipboardPopup.wipeConfirm = true
        clipboardPopup.wipeChoice = 1
    }

    function confirmWipe(): void {
        const wipe = clipboardPopup.wipeChoice === 1

        clipboardPopup.wipeConfirm = false

        if (!wipe)
            return

        bar.closePopups()
        Quickshell.execDetached(["cliphist", "wipe"])
    }

    function copySelection(entry: var): void {
        bar.closePopups()

        copyProbe.command = [
            "sh",
            "-c",
            'printf "%s\\n" "$1" | cliphist decode | wl-copy',
            "qs",
            entry.line
        ]
        copyProbe.running = true
    }

    Process {
        id: deleteProbe

        onExited: exitCode => {
            clipboardPopup.deleteQueue.shift()

            if (clipboardPopup.deleteQueue.length > 0)
                clipboardPopup.runNextDelete()
            else
                listProbe.running = true
        }
    }

    Process {
        id: copyProbe

        onExited: exitCode => {
            if (exitCode !== 0)
                return

            pasteTimer.start()
        }
    }

    Timer {
        id: pasteTimer

        interval: 100
        repeat: false

        onTriggered: clipboardPopup.pasteIntoActive()
    }

    function pasteIntoActive(): void {
        const terminal = /kitty|alacritty|foot|wezterm|ghostty|konsole|gnome-terminal|xfce4-terminal|terminator|tilix|xterm|rxvt|hyper|tabby|stterm|\bst\b/.test(
            clipboardPopup.activeClass)
        const mods = terminal ? "CTRL, SHIFT" : "CTRL"
        const windowArg = clipboardPopup.activeAddress !== ""
            ? ", window = \"address:" + clipboardPopup.activeAddress + "\""
            : ""

        const req = "hl.dsp.send_shortcut({ mods = \"" + mods +
            "\", key = \"V\"" + windowArg + " })"

        Quickshell.execDetached(["hyprctl", "dispatch", req])
    }

    Process {
        id: focusProbe

        command: [
            "sh",
            "-c",
            "hyprctl activewindow -j 2>/dev/null | jq -r '[.address,.class] | @tsv' 2>/dev/null"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("\t")

                clipboardPopup.activeAddress = parts[0] ?? ""
                clipboardPopup.activeClass = (parts[1] ?? "").toLowerCase()
            }
        }
    }

    Process {
        id: listProbe

        command: [
            "sh",
            "-c",
            "cliphist list 2>/dev/null"
        ]

        stdout: StdioCollector {
            onStreamFinished: clipboardPopup.parseHistory(text)
        }
    }

    Rectangle {
        anchors.fill: parent

        radius: 0

        color: Palette.bg

        border.width: 0

        Column {
            anchors {
                fill: parent
                margins: Palette.popupPadding
            }

            spacing: Palette.popupSpacing

            Text {
                id: titleText

                x: 10
                width: parent.width - 10

                text: "󰅇 Paste from history"

                color: Palette.fg

                font.family: Palette.font
                font.pixelSize: Palette.px12

                elide: Text.ElideRight
            }

            ListView {
                id: list

                width: parent.width
                height: 10 * Palette.rowHeight + 9 * 4

                clip: true

                model: clipboardPopup.allEntries

                spacing: 4

                onCountChanged: {
                    if (currentIndex >= count)
                        currentIndex = Math.max(0, count - 1)
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool selected:
                        list.currentIndex === index

                    width: list.width
                    height: Palette.rowHeight

                    radius: 0

                    color: selected ? Palette.accent
                        : rowPaste.containsMouse ? Palette.hoverBg
                        : "transparent"
                    border.width: selected ? 1 : 0
                    border.color: selected
                        ? Palette.accent : Palette.dim

                    MouseArea {
                        id: rowPaste

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            list.currentIndex = index
                            clipboardPopup.pasteSelected()
                        }
                    }

                    Text {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                        }

                        width: parent.width - 56

                        text: modelData.preview !== ""
                            ? modelData.preview
                            : "󰆏 Image"

                        color: selected ? Palette.onAccent
                            : rowPaste.containsMouse ? Palette.fg : Palette.dim

                        font.family: Palette.font
                        font.pixelSize: Palette.px12

                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: rowDelete

                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            right: parent.right
                        }

                        width: 36

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: clipboardPopup.deleteEntry(modelData)

                        Text {
                            anchors.centerIn: parent

                            text: "✕"

                            color: selected ? Palette.onAccent
                                : rowDelete.containsMouse
                                ? Palette.fg : Palette.dim

                            font.family: Palette.font
                            font.pixelSize: Palette.px12
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: Palette.rowHeight

                radius: 0

                color: Palette.surface
                border.width: 0

                Text {
                    anchors.centerIn: parent

                    visible: !clipboardPopup.wipeConfirm

                    text: "Wipe history"

                    color: Palette.dim

                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                }

                MouseArea {
                    anchors.fill: parent

                    visible: !clipboardPopup.wipeConfirm

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: clipboardPopup.requestWipe()
                }

                Row {
                    anchors.fill: parent

                    visible: clipboardPopup.wipeConfirm

                    spacing: 8

                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: parent.height

                        radius: 0

                        color: "transparent"
                        border.width: clipboardPopup.wipeChoice === 0 ? 1 : 0
                        border.color: clipboardPopup.wipeChoice === 0
                            ? Palette.fg : Palette.dim

                        Text {
                            anchors.centerIn: parent

                            text: "No"

                            color: clipboardPopup.wipeChoice === 0
                                ? Palette.fg : Palette.dim

                            font.family: Palette.font
                            font.pixelSize: Palette.px12
                        }

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                clipboardPopup.wipeChoice = 0
                                clipboardPopup.confirmWipe()
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: parent.height

                        radius: 0

                        color: "transparent"
                        border.width: clipboardPopup.wipeChoice === 1 ? 1 : 0
                        border.color: clipboardPopup.wipeChoice === 1
                            ? Palette.fg : Palette.dim

                        Text {
                            anchors.centerIn: parent

                            text: "Yes"

                            color: clipboardPopup.wipeChoice === 1
                                ? Palette.fg : Palette.dim

                            font.family: Palette.font
                            font.pixelSize: Palette.px12
                        }

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                clipboardPopup.wipeChoice = 1
                                clipboardPopup.confirmWipe()
                            }
                        }
                    }
                }
            }

            Text {
                id: hintText

                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                text: "jk move · ↵ paste · d delete · D wipe"

                wrapMode: Text.WordWrap

                color: Palette.dim

                font.family: Palette.font
                font.pixelSize: Palette.px10
            }
        }
    }
}
