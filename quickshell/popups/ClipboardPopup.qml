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
    property string thumbDir: "/tmp/qs-cliphist-thumbs"
    property var thumbs: ({})
    property bool thumbPending: false
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
            const id = line.slice(0, tab);
            const preview = line.slice(tab + 1);
            const isImage = preview.startsWith("[[ binary data");
            const sizeMatch = isImage ? preview.match(/(\d+(?:\.\d+)?\s*[KMGT]?i?B)/) : null;
            const fmtMatch = isImage ? preview.match(/(?:binary data\s+(?:\d+(?:\.\d+)?\s*[KMGT]?i?B)\s+)([A-Za-z0-9.+-]+(?:\/[A-Za-z0-9.+-]+)?)/) : null;
            const dimsMatch = isImage ? preview.match(/(\d+x\d+)/) : null;
            const size = sizeMatch ? sizeMatch[1] : "";
            const dims = dimsMatch ? dimsMatch[1] : "";
            let mime = "image/png";
            if (fmtMatch) {
                const fmt = fmtMatch[1].toLowerCase();
                mime = fmt.indexOf("/") >= 0 ? fmt : "image/" + (fmt === "jpg" ? "jpeg" : fmt);
            }
            const bits = [];
            if (dims !== "")
                bits.push(dims);
            if (size !== "")
                bits.push(size);
            const label = isImage ? (bits.length > 0 ? bits.join(" · ") : "Image") : "";
            out.push({line: line, id: id, preview: preview, isImage: isImage, mime: mime, label: label});
        }
        root.entries = out;
        if (out.length > 0) {
            clipList.currentIndex = Math.min(root.pendingIndex, out.length - 1);
            clipList.positionViewAtIndex(clipList.currentIndex, ListView.Contain);
        } else {
            clipList.currentIndex = -1;
        }
        root.requestThumbs();
    }
    function requestThumbs(): void {
        if (thumbProbe.running) {
            root.thumbPending = true;
            return;
        }
        const lines = [];
        for (let i = 0; i < root.entries.length && lines.length < 30; i++) {
            const e = root.entries[i];
            if (e && e.isImage && !root.thumbs[e.id])
                lines.push(e.line);
        }
        if (lines.length === 0)
            return;
        thumbProbe.command = ["sh", "-c", 'dir="$1"; shift; mkdir -p "$dir"; for line in "$@"; do id=$(printf "%s" "$line" | cut -f1); f="$dir/$id.png"; if [ ! -s "$f" ]; then printf "%s\\n" "$line" | cliphist decode > "$f" 2>/dev/null; fi; if [ -s "$f" ]; then printf "%s\\t%s\\n" "$id" "$f"; fi; done', "qs", root.thumbDir].concat(lines);
        thumbProbe.running = true;
    }
    function applyThumbs(text: string): void {
        const next = Object.assign({}, root.thumbs);
        let changed = false;
        for (const line of text.split("\n")) {
            if (line.trim() === "")
                continue;
            const tab = line.indexOf("\t");
            if (tab <= 0)
                continue;
            next[line.slice(0, tab)] = line.slice(tab + 1);
            changed = true;
        }
        if (changed)
            root.thumbs = next;
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
        if (entry.id !== undefined && entry.id !== "") {
            Quickshell.execDetached(["rm", "-f", root.thumbDir + "/" + entry.id + ".png"]);
            if (root.thumbs[entry.id]) {
                const next = Object.assign({}, root.thumbs);
                delete next[entry.id];
                root.thumbs = next;
            }
        }
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
        Quickshell.execDetached(["sh", "-c", 'cliphist wipe; rm -f "$1"/*.png', "qs", root.thumbDir]);
        root.thumbs = {};
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
        if (entry.isImage)
            copyProbe.command = ["sh", "-c", 'printf "%s\\n" "$1" | cliphist decode | wl-copy -t "$2"', "qs", entry.line, entry.mime && entry.mime !== "" ? entry.mime : "image/png"];
        else
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
    Process {
        id: thumbProbe
        stdout: StdioCollector {
            onStreamFinished: root.applyThumbs(text)
        }
        onExited: {
            if (root.thumbPending) {
                root.thumbPending = false;
                root.requestThumbs();
            }
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
                rowHeight: modelData.isImage ? 80 : Services.Theme.rowHeight
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
                Image {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 10
                        topMargin: 6
                        bottomMargin: 6
                    }
                    width: 144
                    readonly property string thumbSource: modelData.isImage && root.thumbs[modelData.id] ? "file://" + root.thumbs[modelData.id] : ""
                    source: thumbSource
                    visible: modelData.isImage && thumbSource !== ""
                    asynchronous: true
                    cache: true
                    smooth: true
                    sourceSize.width: 288
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    verticalAlignment: Image.AlignVCenter
                }
                Text {
                    visible: modelData.isImage
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 164
                    }
                    width: parent.width - 204
                    text: modelData.label
                    color: row.selected ? Services.Theme.accentFg : row.isHovered ? Services.Theme.fg : Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    elide: Text.ElideRight
                }
                Text {
                    visible: !modelData.isImage
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
