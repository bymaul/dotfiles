import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import "../components"
import "../services" as Services
import "control"
BasePopup {
    id: root
    property var body: null
    extraGrabWindows: root.body != null ? [root.body] : []
    implicitWidth: Services.Theme.popupWidth
    readonly property bool hasHistory: Services.Notifs.history.length > 0
    readonly property int calendarFixedHeight: root.body?.calendarFixedHeight ?? 0
    readonly property int maxStackedHeight: Math.max(0, root.anchorScreenHeight - Services.Theme.popupTopGap - Services.Theme.popupMargin - (root.anchorFullscreen ? 0 : Services.Theme.barHeight))
    readonly property int panelMaxHeight: Math.max(0, root.maxStackedHeight - Services.Theme.popupSpacing - root.calendarFixedHeight)
    readonly property int chromeHeight: fixedRows.implicitHeight + (root.hasHistory ? 2 * Services.Theme.popupSpacing + Services.Theme.rowHeight : 0)
    readonly property int baseHeight: 2 * Services.Theme.popupPadding + root.chromeHeight
    readonly property int listCap: Math.max(64, root.panelMaxHeight - root.baseHeight)
    readonly property int listHeight: root.hasHistory ? Math.min(root.listCap, historyList.contentHeight) : 0
    implicitHeight: root.baseHeight + root.listHeight
    PanelNavKeys {
        host: root
        panel: root
    }
    onVisibleChanged: {
        if (visible && !wasVisible) {
            selectedIndex = 0;
            actionIndex = -1;
            mprisCol = 1;
            root.clampSelection();
            root.captureAnchor();
            root.historySpan = Services.Notifs.history.length > 0 ? Services.Notifs.history.length + 1 : 0;
            root.pendingCalendarShift = 0;
            trayRow.reset();
        }
        Services.Notifs.setSuppressed(visible);
        Services.Notifs.historyVisible = visible;
        Services.Notifs.markRead();
        if (visible)
            historyPolish.restart();
    }
    readonly property var mprisPlayer: Services.Media.activePlayer
    readonly property int playerCount: Services.Media.usableCount
    property int selectedIndex: 0
    property int actionIndex: -1
    property double lastEscapeAt: 0
    property double lastCalendarExitAt: 0
    property string anchorKind: ""
    property int anchorSeq: -1
    property int historySpan: 0
    property int pendingCalendarShift: 0
    onSelectedIndexChanged: root.captureAnchor()
    property int mprisCol: 1
    property var micSource: Services.Media.source
    readonly property var audioSink: Services.Media.sink
    readonly property var sections: {
        const s = [];
        if (Services.Media.brightnessAvailable)
            s.push({ kind: "brightness", count: 1 });
        s.push({ kind: "volume", count: 1 });
        s.push({ kind: "audio", count: 1 });
        if (root.mprisPlayer !== null)
            s.push({ kind: "mpris", count: 1 });
        s.push({ kind: "tile", count: 9 });
        if (trayRow.visible)
            s.push({ kind: "tray", count: 1 });
        if (root.hasHistory) {
            s.push({ kind: "clear", count: 1 });
            s.push({ kind: "history", count: Services.Notifs.history.length });
        }
        s.push({ kind: "calendar", count: 1 });
        let start = 0;
        for (const e of s) {
            e.start = start;
            start += e.count;
        }
        return s;
    }
    function sectionStart(kind: string): int {
        const s = root.sections.find(e => e.kind === kind);
        return s ? s.start : -1;
    }
    function volumeIdx(): int {
        return root.sectionStart("volume");
    }
    function mprisIdx(): int {
        return root.sectionStart("mpris");
    }
    function trayIdx(): int {
        return root.sectionStart("tray");
    }
    function mprisMaxCol(): int {
        return root.playerCount > 1 ? 3 : 2;
    }
    function firstTileIdx(): int {
        return root.sectionStart("tile");
    }
    function clearIdx(): int {
        return root.sectionStart("clear");
    }
    function firstHistIdx(): int {
        return root.sectionStart("history");
    }
    function firstCalIdx(): int {
        return root.sectionStart("calendar");
    }
    function calCard(): var {
        return root.body?.calendar ?? null;
    }
    function exitCalendarFocus(): void {
        if (root.selectedKind() !== "calendar")
            return;
        actionIndex = -1;
        root.stepSelection(-1);
    }
    function handleEscape(): void {
        const now = Date.now();
        if (now - root.lastEscapeAt < 200)
            return;
        root.lastEscapeAt = now;
        if (trayRow.visible && trayRow.expanded) {
            trayRow.back();
            return;
        }
        if (root.selectedKind() === "calendar") {
            root.exitCalendarFocus();
            return;
        }
        root.close();
    }
    function cancelOrClose(): void {
        root.handleEscape();
    }
    function quitAction(): void {
        root.handleEscape();
    }
    function escArmed(): bool {
        return true;
    }
    function quitArmed(): bool {
        return true;
    }
    function itemCount(): int {
        const last = root.sections[root.sections.length - 1];
        return last.start + last.count;
    }
    function clampSelection(): void {
        selectedIndex = Services.Theme.clamp(selectedIndex, 0, root.itemCount() - 1);
        root.clampAction();
    }
    function selectedActions(): var {
        if (root.selectedKind() !== "history")
            return [];
        const item = Services.Notifs.history[root.selectedHistItem()] ?? null;
        return Services.Notifs.secondaryActionsOf(item?.live?.actions ?? []);
    }
    function actionCount(): int {
        return root.selectedActions().length;
    }
    function clampAction(): void {
        if (root.selectedKind() !== "history" || root.actionCount() === 0)
            actionIndex = -1;
        else
            actionIndex = Services.Theme.clamp(actionIndex, -1, root.actionCount() - 1);
    }
    function selectIndex(i: int): void {
        if (selectedIndex === i && actionIndex === -1)
            return;
        selectedIndex = i;
        actionIndex = -1;
        root.clampSelection();
        root.revealSelection();
    }
    function selectAction(histItem: int, actIdx: int): void {
        selectedIndex = root.firstHistIdx() + histItem;
        actionIndex = actIdx;
        root.clampSelection();
        root.revealSelection();
    }
    function selectTray(): void {
        if (trayRow.visible)
            root.selectIndex(trayIdx());
    }
    function focusLastTile(): void {
        selectedIndex = root.firstTileIdx() + 8;
        actionIndex = -1;
        root.clampSelection();
    }
    function captureAnchor(): void {
        const kind = root.selectedKind();
        root.anchorKind = kind;
        root.anchorSeq = kind === "history" ? (Services.Notifs.history[root.selectedHistItem()]?.seq ?? -1) : -1;
    }
    function syncHistorySelection(): void {
        const shift = root.pendingCalendarShift;
        root.pendingCalendarShift = 0;
        if (root.anchorKind === "history") {
            const seq = root.anchorSeq;
            const idx = seq >= 0 ? Services.Notifs.history.findIndex(h => h.seq === seq) : -1;
            if (idx >= 0) {
                selectedIndex = root.firstHistIdx() + idx;
                root.clampSelection();
                root.revealAt(idx);
            } else {
                actionIndex = -1;
                if (root.hasHistory)
                    selectedIndex = Math.min(root.selectedIndex, root.firstHistIdx() + Services.Notifs.history.length - 1);
                root.clampSelection();
                if (!root.hasHistory)
                    root.focusLastTile();
            }
        } else if (root.anchorKind === "calendar") {
            selectedIndex += shift;
            root.clampSelection();
        } else if (root.anchorKind === "clear" && !root.hasHistory) {
            root.focusLastTile();
        }
        root.captureAnchor();
    }
    Connections {
        target: Services.Notifs
        function onHistoryChanged() {
            const count = Services.Notifs.history.length;
            const span = count > 0 ? count + 1 : 0;
            const shift = span - root.historySpan;
            root.historySpan = span;
            if (!root.visible)
                return;
            root.pendingCalendarShift += shift;
            Qt.callLater(root.syncHistorySelection);
        }
    }
    onMprisPlayerChanged: {
        if (root.visible)
            root.clampSelection();
    }
    function revealSelection(): void {
        const kind = root.selectedKind();
        if (kind === "calendar")
            return;
        if (kind === "history")
            root.revealAt(root.selectedHistItem());
        else if (kind === "clear")
            root.revealAt(0);
    }
    function revealAt(i: int): void {
        const item = historyList.itemAtIndex(i);
        if (item === null) {
            historyList.positionViewAtIndex(i, ListView.Contain);
            return;
        }
        const top = historyList.contentY;
        if (item.y < top || item.y + item.height > top + historyList.height)
            historyList.positionViewAtIndex(i, ListView.Contain);
    }
    function stepSelection(dir: int): void {
        actionIndex = -1;
        if (trayRow.visible && root.selectedKind() === "tray" && trayRow.expanded) {
            trayRow.moveInList(dir);
            return;
        }
        selectedIndex += dir;
        root.clampSelection();
        root.revealSelection();
    }
    function sectionStops(): var {
        const stops = [];
        let inMedia = false;
        for (const s of root.sections) {
            const media = s.kind === "brightness" || s.kind === "volume" || s.kind === "audio";
            if (!media || !inMedia)
                stops.push(s.start);
            inMedia = media;
        }
        return stops;
    }
    function stepSection(dir: int): void {
        actionIndex = -1;
        const bounds = root.sectionStops();
        let target = selectedIndex;
        if (dir > 0) {
            for (const b of bounds) {
                if (b > selectedIndex) {
                    target = b;
                    break;
                }
            }
        } else {
            for (let i = bounds.length - 1; i >= 0; i--) {
                if (bounds[i] < selectedIndex) {
                    target = bounds[i];
                    break;
                }
            }
        }
        selectedIndex = target;
        root.clampSelection();
        root.revealSelection();
    }
    function goFirstSection(): void {
        const stops = root.sectionStops();
        if (stops.length === 0)
            return;
        root.selectIndex(stops[0]);
    }
    function goLastSection(): void {
        const stops = root.sectionStops();
        if (stops.length === 0)
            return;
        root.selectIndex(stops[stops.length - 1]);
    }
    function stepVertical(dir: int): void {
        actionIndex = -1;
        if (root.selectedKind() === "calendar") {
            root.calCard()?.moveSelection(dir * 7);
            return;
        }
        if (root.selectedKind() !== "tile") {
            root.stepSelection(dir);
            return;
        }
        const tileStart = root.firstTileIdx();
        const tileEnd = tileStart + 8;
        const target = selectedIndex + dir * 3;
        const tileSection = root.sections.findIndex(s => s.kind === "tile");
        if (target > tileEnd)
            selectedIndex = root.sections[tileSection + 1] ? root.sections[tileSection + 1].start : tileEnd;
        else if (target < tileStart)
            selectedIndex = tileSection > 0 ? root.sections[tileSection - 1].start : tileStart;
        else
            selectedIndex = target;
        root.clampSelection();
        root.revealSelection();
    }
    function selectedKind(): string {
        for (const s of root.sections) {
            if (selectedIndex >= s.start && selectedIndex < s.start + s.count)
                return s.kind;
        }
        return "tile";
    }
    function selectedTile(): int {
        return selectedIndex - root.firstTileIdx();
    }
    function selectedHistItem(): int {
        return selectedIndex - root.firstHistIdx();
    }
    function adjustVolume(delta: real): void {
        Services.Media.adjustVolume(delta);
    }
    function toggleVolumeMute(): void {
        const audio = root.audioSink?.audio;
        if (audio)
            audio.muted = !audio.muted;
    }
    function toggleMicMute(): void {
        const audio = root.micSource?.audio;
        if (audio)
            audio.muted = !audio.muted;
    }
    function openAudio(input: bool): void {
        root.bar.openAudio(input === true);
    }
    function cycleProfileTile(): void {
        if (Services.Power.asusAvailable)
            Services.Power.cycleAsusProfile(1);
        else
            Services.Power.cycleProfile();
    }
    function adjustSelected(dir: int): void {
        const kind = root.selectedKind();
        if (kind === "brightness")
            Services.Media.setBrightness(Services.Media.brightness + dir * Services.Theme.brightnessStep, true);
        else if (kind === "volume")
            root.adjustVolume(dir * Services.Theme.volumeStep);
        else if (kind === "audio")
            return;
        else if (kind === "mpris")
            mprisCol = Services.Theme.clamp(mprisCol + dir, 0, root.mprisMaxCol());
        else if (kind === "tray") {
            if (dir > 0)
                trayRow.forward();
            else
                trayRow.back();
        }
        else if (kind === "calendar")
            root.calCard()?.moveSelection(dir);
        else if (kind === "history")
            root.moveAction(dir);
        else
            root.stepSelection(dir);
    }
    function moveAction(dir: int): void {
        const count = root.actionCount();
        if (count === 0) {
            root.stepSelection(dir);
            return;
        }
        if (actionIndex === -1) {
            if (dir > 0)
                actionIndex = 0;
            else
                root.stepSelection(dir);
            return;
        }
        const next = actionIndex + dir;
        if (next < 0)
            actionIndex = -1;
        else if (next >= count)
            actionIndex = count - 1;
        else
            actionIndex = next;
    }
    function focusNext(): void {
        const kind = root.selectedKind();
        if (kind === "history" && root.actionCount() > 0) {
            if (actionIndex === -1) {
                actionIndex = 0;
                return;
            }
            if (actionIndex < root.actionCount() - 1) {
                actionIndex += 1;
                return;
            }
            actionIndex = -1;
        }
        root.stepSelection(1);
    }
    function focusPrev(): void {
        const kind = root.selectedKind();
        if (kind === "history" && actionIndex >= 0) {
            actionIndex -= 1;
            return;
        }
        root.stepSelection(-1);
    }
    function activateMpris(col: int): void {
        const player = root.mprisPlayer;
        if (col === 0)
            Services.Media.mediaPrev(player);
        else if (col === 2)
            Services.Media.mediaNext(player);
        else if (col === 3) {
            Services.Media.cyclePlayer();
            root.mprisCol = Services.Theme.clamp(root.mprisCol, 0, root.mprisMaxCol());
        } else
            Services.Media.mediaToggle(player);
    }
    function activateActionAt(actIdx: int): void {
        const histItem = root.selectedHistItem();
        const item = Services.Notifs.history[histItem] ?? null;
        const live = item?.live ?? null;
        const actions = Services.Notifs.secondaryActionsOf(live?.actions ?? []);
        if (!live || actIdx < 0 || actIdx >= actions.length) {
            actionIndex = -1;
            return;
        }
        try {
            Services.Notifs.activateAction(live, actions[actIdx]);
        } catch (_) {}
        Services.Notifs.dismissHistoryAfterAction(histItem, live);
        actionIndex = -1;
        root.clampSelection();
        bar.closePopups();
    }
    function dismissSelected(): void {
        if (root.selectedKind() !== "history")
            return;
        actionIndex = -1;
        Services.Notifs.dismissHistoryAt(root.selectedHistItem());
        root.clampSelection();
    }
    function activateDefaultAction(): void {
        const histItem = root.selectedHistItem();
        const item = Services.Notifs.history[histItem] ?? null;
        const live = item?.live ?? null;
        if (!live || (live?.actions ?? []).length === 0) {
            if (live && live.resident === true) {
                actionIndex = -1;
                root.clampSelection();
                bar.closePopups();
            } else {
                root.dismissSelected();
            }
            return;
        }
        try {
            Services.Notifs.activateDefault(live);
        } catch (_) {}
        Services.Notifs.dismissHistoryAfterAction(histItem, live);
        actionIndex = -1;
        root.clampSelection();
        bar.closePopups();
    }
    function activateSelected(): void {
        const kind = root.selectedKind();
        if (kind === "volume") {
            root.toggleVolumeMute();
            return;
        }
        if (kind === "audio") {
            root.openAudio(false);
            return;
        }
        if (kind === "brightness")
            return;
        if (kind === "mpris") {
            root.activateMpris(mprisCol);
            return;
        }
        if (kind === "tray") {
            trayRow.activate();
            return;
        }
        if (kind === "clear") {
            actionIndex = -1;
            Services.Notifs.clearHistory();
            root.clampSelection();
            return;
        }
        if (kind === "calendar") {
            root.calCard()?.openSelected();
            return;
        }
        if (kind === "history") {
            if (actionIndex >= 0) {
                root.activateActionAt(actionIndex);
                return;
            }
            root.activateDefaultAction();
            return;
        }
        tileGrid.activateTile(root.selectedTile());
    }
    PwObjectTracker {
        objects: [root.micSource]
    }
    Timer {
        id: historyPolish
        interval: Services.Theme.focusDelay
        repeat: false
        onTriggered: {
            if (root.visible && root.selectedIndex === 0)
                historyList.positionViewAtIndex(0, ListView.Beginning);
        }
    }
    PopupCard {
        id: card
        Column {
            id: fixedRows
            width: parent.width
            spacing: Services.Theme.popupSpacing
            StatusRow {
                id: statusRow
            }
            BrightnessRow {
                id: brightnessRow
                popup: root
            }
            Row {
                width: parent.width
                spacing: Services.Theme.popupSpacing
                VolumeRow {
                    id: volumeRow
                    width: parent.width - audioTile.width - Services.Theme.popupSpacing
                    popup: root
                }
                AudioTile {
                    id: audioTile
                    selected: root.selectedKind() === "audio"
                    onClicked: root.openAudio(false)
                }
            }
            MprisRow {
                id: mprisRow
                popup: root
            }
            TileGrid {
                id: tileGrid
                popup: root
            }
            TrayRow {
                id: trayRow
                popup: root
            }
        }
        Rectangle {
            width: parent.width
            height: Services.Theme.rowHeight
            visible: root.hasHistory
            color: Services.Theme.bg
            Row {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 60
                    text: "Notifications (" + Services.Notifs.history.length + ")"
                    color: Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    elide: Text.ElideRight
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 60
                    horizontalAlignment: Text.AlignRight
                    text: "Clear"
                    readonly property bool selected: root.selectedKind() === "clear"
                    color: selected ? Services.Theme.accent : clearArea.containsMouse ? Services.Theme.fg : Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    font.underline: selected
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.actionIndex = -1;
                            Services.Notifs.clearHistory();
                            root.clampSelection();
                        }
                    }
                }
            }
        }
        Item {
            width: parent.width
            height: root.listHeight
            visible: root.hasHistory
            ListView {
                id: historyList
                anchors.fill: parent
                clip: true
                cacheBuffer: 400
                model: Services.Notifs.history
                spacing: Services.Theme.popupSpacing
                delegate: Rectangle {
                    id: historyCard
                    required property var modelData
                    required property int index
                    readonly property bool selected: root.selectedIndex === root.firstHistIdx() + index
                    readonly property string rawIcon: modelData.icon ?? ""
                    readonly property bool isHovered: cardArea.containsMouse
                    width: historyList.width
                    height: content.height + 16
                    color: selected ? Services.Theme.activeBg : historyCard.isHovered ? Services.Theme.hoverBg : Services.Theme.surface
                    border.width: selected ? 1 : 0
                    border.color: historyCard.isHovered ? Services.Theme.fg : historyCard.modelData.critical ? Services.Theme.danger : Services.Theme.accent

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: 1
                        visible: modelData.critical
                        color: Services.Theme.danger
                    }
                    MouseArea {
                        id: cardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            mouse.accepted = true;
                            const panel = root;
                            const idx = historyCard.index;
                            const live = historyCard.modelData.live;
                            panel.actionIndex = -1;
                            if (live == null) {
                                Services.Notifs.dismissHistoryAt(idx);
                                return;
                            }
                            try {
                                Services.Notifs.activateDefault(live);
                            } catch (_) {}
                            Services.Notifs.dismissHistoryAfterAction(idx, live);
                            panel.bar.closePopups();
                        }
                    }
                    Column {
                        id: content
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 6
                        Row {
                            width: parent.width
                            spacing: 8
                            NotificationIcon {
                                id: historyIcon
                                rawIcon: historyCard.rawIcon
                                tint: historyCard.modelData.critical ? Services.Theme.danger : "transparent"
                            }
                            Column {
                                width: parent.width - (historyIcon.showIcon ? historyIcon.width + 8 : 0)
                                spacing: 2
                                Row {
                                    width: parent.width
                                    spacing: 8
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 52
                                        text: modelData.summary || modelData.app || ""
                                        color: Services.Theme.fg
                                        font.family: Services.Theme.font
                                        font.pixelSize: Services.Theme.px12
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 44
                                        horizontalAlignment: Text.AlignRight
                                        text: {
                                            Services.Notifs.timeTick;
                                            return Services.Notifs.timeAgo(modelData.time);
                                        }
                                        color: Services.Theme.dim
                                        font.family: Services.Theme.font
                                        font.pixelSize: Services.Theme.px10
                                    }
                                }
                                Text {
                                    width: parent.width
                                    visible: (modelData.body ?? "") !== ""
                                    text: Services.Notifs.richBody(modelData.body)
                                    color: Services.Theme.dim
                                    font.family: Services.Theme.font
                                    font.pixelSize: Services.Theme.px12
                                    textFormat: Text.StyledText
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: Services.Theme.historyBodyMaxLines
                                    elide: Text.ElideRight
                                }
                                ActionPills {
                                    width: parent.width
                                    actions: Services.Notifs.secondaryActionsOf(modelData.live?.actions ?? [])
                                    focusedIndex: historyCard.selected ? root.actionIndex : -1
                                    onPicked: action => {
                                        const panel = root;
                                        const idx = historyCard.index;
                                        const live = modelData.live;
                                        try {
                                            Services.Notifs.activateAction(live, action);
                                        } catch (_) {}
                                        panel.actionIndex = -1;
                                        Services.Notifs.dismissHistoryAfterAction(idx, live);
                                        panel.bar.closePopups();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
