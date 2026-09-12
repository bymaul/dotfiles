import QtQuick
import Quickshell
import "../services" as Services
import "../Palette.js" as Palette

BasePopup {
    id: launcherPopup

    anchorMode: "center"

    implicitWidth: Palette.popupWidth
    implicitHeight: 16 + Palette.rowHeight + Palette.popupSpacing * 2 + (10 * Palette.rowHeight + 9 * 4) + hintText.implicitHeight

    Shortcut {
        sequence: "Escape"
        onActivated: bar.closePopups()
    }

    Shortcut {
        sequence: "Down"
        enabled: launcherPopup.visible && !queryField.activeFocus
        onActivated: launcherPopup.stepSelection(1)
    }
    Shortcut {
        sequence: "Up"
        enabled: launcherPopup.visible && !queryField.activeFocus
        onActivated: launcherPopup.stepSelection(-1)
    }
    Shortcut {
        sequence: "Return"
        enabled: launcherPopup.visible && !queryField.activeFocus
        onActivated: launcherPopup.launch()
    }
    Shortcut {
        sequence: "Enter"
        enabled: launcherPopup.visible && !queryField.activeFocus
        onActivated: launcherPopup.launch()
    }
    Shortcut {
        sequence: "Tab"
        enabled: launcherPopup.visible
        onActivated: launcherPopup.stepSelection(1)
    }
    Shortcut {
        sequence: "Shift+Tab"
        enabled: launcherPopup.visible
        onActivated: launcherPopup.stepSelection(-1)
    }
    Shortcut {
        sequence: "Ctrl+N"
        enabled: launcherPopup.visible
        onActivated: launcherPopup.stepSelection(1)
    }
    Shortcut {
        sequence: "Ctrl+P"
        enabled: launcherPopup.visible
        onActivated: launcherPopup.stepSelection(-1)
    }
    Shortcut {
        sequence: "Ctrl+Y"
        enabled: launcherPopup.visible
        onActivated: launcherPopup.launch()
    }

    property var appsCache: null
    property var entries: []

    onVisibleChanged: {
        if (visible) {
            launcherPopup.appsCache = DesktopEntries.applications.values;
            Services.RunMode.refresh();
            Services.LaunchHistory.load();
            queryField.text = "";
            launcherPopup.refilter();
            queryField.forceActiveFocus();
        }
    }

    Connections {
        target: Services.RunMode

        function onBinariesChanged() {
            if (launcherPopup.visible && launcherPopup.runMode)
                launcherPopup.refilter();
        }
    }

    Connections {
        target: DesktopEntries.applications

        function onValuesChanged() {
            if (launcherPopup.visible && !launcherPopup.runMode) {
                launcherPopup.appsCache = DesktopEntries.applications.values;
                launcherPopup.refilter();
            }
        }

        function onObjectInsertedPost() {
            if (launcherPopup.visible && !launcherPopup.runMode) {
                launcherPopup.appsCache = DesktopEntries.applications.values;
                launcherPopup.refilter();
            }
        }
    }

    Connections {
        target: Services.LaunchHistory

        function onLoadedChanged() {
            if (launcherPopup.visible)
                launcherPopup.refilter();
        }
    }

    function stepSelection(dir: int): void {
        if (list.count === 0)
            return;
        list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + dir));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    readonly property bool runMode: queryField.text.trim().startsWith(">")

    function refilter(): void {
        if (launcherPopup.runMode) {
            launcherPopup.refilterRun(queryField.text.trim().slice(1).trim().toLowerCase());
        } else {
            launcherPopup.refilterApps(queryField.text.toLowerCase().trim());
        }
    }

    function matchScore(text: string, q: string): int {
        if (q === "")
            return 1;

        if (text === q)
            return 0;

        if (text.startsWith(q))
            return 1;

        if (text.includes(q))
            return 2;

        return 3;
    }

    function sortScored(out: var): void {
        out.sort((a, b) => (a.score - b.score) || ((b.use ?? 0) - (a.use ?? 0)) || ((b.last ?? 0) - (a.last ?? 0)) || a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
    }

    function refilterApps(q: string): void {
        const apps = launcherPopup.appsCache ?? [];
        const out = [];

        for (const app of apps) {
            const name = app.name ?? app.genericName ?? "";

            if (name === "")
                continue;
            const haystacks = [app.name ?? "", app.genericName ?? "", app.comment ?? ""].concat(app.keywords ?? []);

            let best = 3;

            for (const h of haystacks) {
                best = Math.min(best, launcherPopup.matchScore(h.toLowerCase(), q));

                if (best === 0)
                    break;
            }

            if (best < 3)
                out.push({
                    name: name,
                    entry: app,
                    score: best,
                    use: Services.LaunchHistory.countFor("app:" + (app.id ?? "")),
                    last: Services.LaunchHistory.lastFor("app:" + (app.id ?? ""))
                });
        }

        launcherPopup.sortScored(out);
        launcherPopup.applyResults(out);
    }

    function refilterRun(q: string): void {
        const out = [];

        for (const name of Services.RunMode.binaries) {
            const score = launcherPopup.matchScore(name.toLowerCase(), q);

            if (score < 3)
                out.push({
                    name: name,
                    score: score,
                    use: Services.LaunchHistory.countFor("bin:" + name),
                    last: Services.LaunchHistory.lastFor("bin:" + name)
                });
        }

        launcherPopup.sortScored(out);
        launcherPopup.applyResults(out);
    }

    function applyResults(out: var): void {
        launcherPopup.entries = out;

        if (out.length > 0) {
            list.currentIndex = 0;
            list.positionViewAtIndex(0, ListView.Contain);
        } else {
            list.currentIndex = -1;
        }
    }

    function launch(): void {
        if (launcherPopup.runMode) {
            const rest = queryField.text.trim().slice(1).trim();

            if (rest === "") {
                const picked = launcherPopup.entries[list.currentIndex];

                if (picked) {
                    Services.LaunchHistory.record("bin:" + picked.name);
                    launcherPopup.run([picked.name]);
                }

                return;
            }

            const app = launcherPopup.findApp(rest);

            if (app) {
                Services.LaunchHistory.record("app:" + (app.id ?? ""));
                launcherPopup.runApp(app);
            } else {
                Services.LaunchHistory.record("cmd:" + rest);
                launcherPopup.run(["sh", "-c", rest]);
            }

            return;
        }

        const entry = launcherPopup.entries[list.currentIndex];

        if (!entry)
            return;
        Services.LaunchHistory.record("app:" + (entry.entry.id ?? ""));
        launcherPopup.runApp(entry.entry);
    }

    // Single tokens naming an installed app launch via its desktop
    // entry, so terminal programs get a terminal. Rest runs raw.
    function findApp(rest: string): var {
        if (/\s/.test(rest))
            return null;

        const q = rest.toLowerCase();

        for (const app of launcherPopup.appsCache ?? []) {
            const cmd = app.command && app.command.length > 0 ? app.command[0] : "";
            const base = String(cmd).split("/").pop().toLowerCase();
            const name = (app.name ?? "").toLowerCase();

            if (base !== "" && base === q)
                return app;

            if (name !== "" && name === q)
                return app;
        }

        return null;
    }

    function runApp(entry: var): void {
        const cmd = entry.runInTerminal ? ["kitty"].concat(entry.command) : entry.command;

        launcherPopup.run(cmd);
    }

    function run(cmd: var): void {
        bar.closePopups();
        Quickshell.execDetached(cmd);
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

            Rectangle {
                width: parent.width
                height: Palette.rowHeight

                radius: 0

                color: "transparent"
                border.width: 1
                border.color: launcherPopup.runMode ? Palette.accent : Palette.border

                TextInput {
                    id: queryField

                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }

                    verticalAlignment: TextInput.AlignVCenter

                    color: Palette.fg

                    font.family: Palette.font
                    font.pixelSize: Palette.px13

                    onTextChanged: launcherPopup.refilter()

                    Keys.onUpPressed: launcherPopup.stepSelection(-1)
                    Keys.onDownPressed: launcherPopup.stepSelection(1)
                    Keys.onReturnPressed: launcherPopup.launch()
                    Keys.onEnterPressed: launcherPopup.launch()
                }
            }

            ListView {
                id: list

                width: parent.width
                height: 10 * Palette.rowHeight + 9 * 4

                clip: true

                model: launcherPopup.entries

                spacing: 4

                onCountChanged: {
                    if (currentIndex >= count)
                        currentIndex = Math.max(0, count - 1);
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool selected: list.currentIndex === index

                    width: list.width
                    height: Palette.rowHeight

                    radius: 0

                    color: selected ? Palette.accent : rowHover.containsMouse ? Palette.hoverBg : "transparent"
                    border.width: selected ? 1 : 0
                    border.color: selected ? Palette.accent : Palette.dim

                    MouseArea {
                        id: rowHover

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            list.currentIndex = index;
                            launcherPopup.launch();
                        }
                    }

                    Text {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                        }

                        width: parent.width - 20

                        text: modelData.name

                        color: selected ? Palette.onAccent : rowHover.containsMouse ? Palette.fg : Palette.dim

                        font.family: Palette.font
                        font.pixelSize: Palette.px12

                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                id: hintText

                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                text: "^n/^p move · ^y launch · > command"

                wrapMode: Text.WordWrap

                color: Palette.dim

                font.family: Palette.font
                font.pixelSize: Palette.px10
            }
        }
    }
}
