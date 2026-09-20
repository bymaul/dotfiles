import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../components"
import "../services" as Services
BasePopup {
    id: root
    anchorMode: "middle"
    implicitWidth: Services.Theme.settingsWidth
    implicitHeight: 16 + title.implicitHeight + Services.Theme.rowHeight + Services.Theme.popupSpacing * 3 + Services.Theme.listHeight(Services.Theme.listVisible) + hint.implicitHeight
    function cancelOrClose(): void {
        if (root.wipeConfirm)
            root.wipeConfirm = false;
        else
            root.close();
    }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Down"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Up"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.confirm() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.confirm() }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.confirm() }
    Shortcut { sequence: "d"; enabled: root.visible; onActivated: root.deleteSelected() }
    Shortcut { sequence: "Delete"; enabled: root.visible; onActivated: root.deleteSelected() }
    Shortcut { sequence: "Shift+D"; enabled: root.visible; onActivated: root.requestWipe() }
    Shortcut { sequence: "h"; enabled: root.visible && root.wipeConfirm; onActivated: root.wipeChoice = 0 }
    Shortcut { sequence: "l"; enabled: root.visible && root.wipeConfirm; onActivated: root.wipeChoice = 1 }
    Shortcut { sequence: "Left"; enabled: root.visible && root.wipeConfirm; onActivated: root.wipeChoice = 0 }
    Shortcut { sequence: "Right"; enabled: root.visible && root.wipeConfirm; onActivated: root.wipeChoice = 1 }
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
        stepListView(clipList, dir);
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
        if (!entry)
            return;
        if (copyProbe.running) {
            root.queuedCopy = entry;
            return;
        }
        root.pendingCopy = entry;
        root.queuedCopy = null;
        copyProbe.command = ["sh", "-c", 'printf "%s\\n" "$1" | cliphist decode | wl-copy', "qs", entry.line];
        copyProbe.running = true;
        copyTimeout.restart();
    }
    property var pendingCopy: null
    property var queuedCopy: null
    Timer {
        id: copyTimeout
        interval: 8000
        repeat: false
        onTriggered: {
            if (copyProbe.running)
                copyProbe.running = false;
        }
    }
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
            copyTimeout.stop();
            const entry = root.pendingCopy;
            root.pendingCopy = null;
            if (root.queuedCopy !== null) {
                const next = root.queuedCopy;
                root.queuedCopy = null;
                root.copySelection(next);
                return;
            }
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
        interval: Services.Theme.grabDelay
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
            color: Services.Theme.fg
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px12
            elide: Text.ElideRight
        }
        ListView {
            id: clipList
            width: parent.width
            height: Services.Theme.listHeight(Services.Theme.listVisible)
            clip: true
            model: root.entries
            spacing: Services.Theme.listSpacing
            onCountChanged: clampListView(clipList)
            delegate: ResultRow {
                id: row
                required property var modelData
                required property int index
                selected: clipList.currentIndex === index
                onHovered: {
                    root.wipeConfirm = false;
                    clipList.currentIndex = index;
                    clipList.positionViewAtIndex(index, ListView.Contain);
                }
                onClicked: {
                    clipList.currentIndex = index;
                    root.pasteSelected();
                }
                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    width: parent.width - 56
                    text: modelData.preview !== "" ? modelData.preview : "󰆏 Image"
                    color: row.selected ? Services.Theme.accentFg : row.isHovered ? Services.Theme.fg : Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
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
                        color: row.selected ? Services.Theme.accentFg : deleteArea.containsMouse ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                    }
                }
            }
        }
        Rectangle {
            width: parent.width
            height: Services.Theme.rowHeight
            color: Services.Theme.surface
            Text {
                anchors.centerIn: parent
                visible: !root.wipeConfirm
                text: "Wipe history"
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
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
                onHovered: index => root.wipeChoice = index
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
