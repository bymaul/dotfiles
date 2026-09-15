import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../components"
import "../services" as Services
import "../Palette.js" as Palette
BasePopup {
    id: root
    anchorMode: "center"
    implicitWidth: Palette.popupWidth
    implicitHeight: 16 + title.implicitHeight + Palette.rowHeight + Palette.popupSpacing * 3 + Palette.listHeight(Palette.listVisible) + hint.implicitHeight
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: {
            if (root.wipeConfirm)
                root.wipeConfirm = false;
            else
                root.close();
        }
    }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.confirm() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.confirm() }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.confirm() }
    Shortcut { sequence: "d"; enabled: root.visible; onActivated: root.deleteSelected() }
    Shortcut { sequence: "Shift+D"; enabled: root.visible; onActivated: root.requestWipe() }
    Shortcut { sequence: "h"; enabled: root.visible && root.wipeConfirm; onActivated: root.wipeChoice = 0 }
    Shortcut { sequence: "l"; enabled: root.visible && root.wipeConfirm; onActivated: root.wipeChoice = 1 }
    property var entries: []
    property int pendingIndex: 0
    property var deleteQueue: []
    property string activeAddress: ""
    property string activeClass: ""
    property bool wipeConfirm: false
    property int wipeChoice: 1
    onVisibleChanged: {
        if (visible)
            root.reset();
    }
    function reset(): void {
        activeAddress = "";
        activeClass = "";
        pendingIndex = 0;
        deleteQueue = [];
        wipeConfirm = false;
        wipeChoice = 1;
        focusProbe.running = true;
        listProbe.running = true;
    }
    function parseHistory(text: string): void {
        const out = [];
        for (const line of text.split("\n")) {
            if (line.trim() === "")
                continue;
            const tab = line.indexOf("\t");
            if (tab <= 0)
                continue;
            out.push({line: line, preview: line.slice(tab + 1)});
        }
        root.entries = out;
        if (out.length > 0) {
            clipList.currentIndex = Math.min(root.pendingIndex, out.length - 1);
            clipList.positionViewAtIndex(clipList.currentIndex, ListView.Contain);
        } else {
            clipList.currentIndex = -1;
        }
    }
    function stepSelection(dir: int): void {
        root.wipeConfirm = false;
        if (clipList.count === 0)
            return;
        clipList.currentIndex = Palette.clamp(clipList.currentIndex + dir, 0, clipList.count - 1);
        clipList.positionViewAtIndex(clipList.currentIndex, ListView.Contain);
    }
    function confirm(): void {
        if (root.wipeConfirm)
            root.confirmWipe();
        else
            root.pasteSelected();
    }
    function pasteSelected(): void {
        const entry = root.entries[clipList.currentIndex];
        if (entry)
            root.copySelection(entry);
    }
    function deleteSelected(): void {
        const entry = root.entries[clipList.currentIndex];
        if (entry)
            root.deleteEntry(entry);
    }
    function deleteEntry(entry: var): void {
        root.pendingIndex = Math.max(0, clipList.currentIndex);
        root.wipeConfirm = false;
        root.deleteQueue.push(entry.line);
        root.runNextDelete();
    }
    function runNextDelete(): void {
        if (deleteProbe.running || root.deleteQueue.length === 0)
            return;
        deleteProbe.command = ["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "qs", root.deleteQueue[0]];
        deleteProbe.running = true;
    }
    function requestWipe(): void {
        root.wipeConfirm = true;
        root.wipeChoice = 1;
    }
    function confirmWipe(): void {
        const wipe = root.wipeChoice === 1;
        root.wipeConfirm = false;
        if (!wipe)
            return;
        bar.closePopups();
        Quickshell.execDetached(["cliphist", "wipe"]);
    }
    function copySelection(entry: var): void {
        if (!entry || copyProbe.running)
            return;
        root.pendingCopy = entry;
        copyProbe.command = ["sh", "-c", 'printf "%s\\n" "$1" | cliphist decode | wl-copy', "qs", entry.line];
        copyProbe.running = true;
    }
    property var pendingCopy: null
    Process {
        id: deleteProbe
        onExited: exitCode => {
            if (exitCode !== 0) {
                listProbe.running = true;
                return;
            }
            root.deleteQueue.shift();
            if (root.deleteQueue.length > 0)
                root.runNextDelete();
            else
                listProbe.running = true;
        }
    }
    Process {
        id: copyProbe
        onExited: exitCode => {
            const entry = root.pendingCopy;
            root.pendingCopy = null;
            if (exitCode !== 0) {
                Services.Notifs.notify({app: "clipboard", summary: "Copy failed", body: "cliphist decode or wl-copy failed", timeout: 5000});
                return;
            }
            if (!entry)
                return;
            bar.closePopups();
            pasteTimer.start();
        }
    }
    Timer {
        id: pasteTimer
        interval: Palette.grabDelay
        repeat: false
        onTriggered: root.pasteIntoActive()
    }
    function pasteIntoActive(): void {
        const terminal = /kitty|alacritty|foot|wezterm|ghostty|konsole|gnome-terminal|xfce4-terminal|terminator|tilix|xterm|rxvt|hyper|tabby|stterm|\bst\b/.test(root.activeClass);
        const mods = terminal ? "CTRL, SHIFT" : "CTRL";
        const windowArg = root.activeAddress !== "" ? ", window = \"address:" + root.activeAddress + "\"" : "";
        Hyprland.dispatch("hl.dsp.send_shortcut({ mods = \"" + mods + "\", key = \"V\"" + windowArg + " })");
    }
    Process {
        id: focusProbe
        command: ["sh", "-c", "hyprctl activewindow -j 2>/dev/null | jq -r '[.address,.class] | @tsv' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("\t");
                root.activeAddress = parts[0] ?? "";
                root.activeClass = (parts[1] ?? "").toLowerCase();
            }
        }
    }
    Process {
        id: listProbe
        command: ["sh", "-c", "cliphist list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.parseHistory(text)
        }
    }
    PopupCard {
        Text {
            id: title
            x: 10
            width: parent.width - 10
            text: "󰅇 Paste from history"
            color: Palette.fg
            font.family: Palette.font
            font.pixelSize: Palette.px12
            elide: Text.ElideRight
        }
        ListView {
            id: clipList
            width: parent.width
            height: Palette.listHeight(Palette.listVisible)
            clip: true
            model: root.entries
            spacing: Palette.listSpacing
            onCountChanged: {
                if (currentIndex >= count)
                    currentIndex = Math.max(0, count - 1);
            }
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool selected: clipList.currentIndex === index
                width: clipList.width
                height: Palette.rowHeight
                color: selected ? Palette.accent : rowArea.containsMouse ? Palette.hoverBg : "transparent"
                border.width: selected ? 1 : 0
                border.color: selected ? Palette.accent : Palette.dim
                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        clipList.currentIndex = index;
                        root.pasteSelected();
                    }
                }
                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    width: parent.width - 56
                    text: modelData.preview !== "" ? modelData.preview : "󰆏 Image"
                    color: selected ? Palette.onAccent : rowArea.containsMouse ? Palette.fg : Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: deleteArea
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.right
                    }
                    width: 36
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.deleteEntry(modelData)
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: selected ? Palette.onAccent : deleteArea.containsMouse ? Palette.fg : Palette.dim
                        font.family: Palette.font
                        font.pixelSize: Palette.px12
                    }
                }
            }
        }
        Rectangle {
            width: parent.width
            height: Palette.rowHeight
            color: Palette.surface
            Text {
                anchors.centerIn: parent
                visible: !root.wipeConfirm
                text: "Wipe history"
                color: Palette.dim
                font.family: Palette.font
                font.pixelSize: Palette.px12
            }
            MouseArea {
                anchors.fill: parent
                visible: !root.wipeConfirm
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.requestWipe()
            }
            ConfirmRow {
                anchors.fill: parent
                visible: root.wipeConfirm
                choice: root.wipeChoice
                noLabel: "No"
                yesLabel: "Yes"
                onPicked: index => {
                    root.wipeChoice = index;
                    root.confirmWipe();
                }
            }
        }
        HintText {
            id: hint
            text: "jk move · ↵ paste · d delete · D wipe"
        }
    }
}
