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
    property var historyWindow: null
    extraGrabWindows: root.historyWindow != null ? [root.historyWindow] : []
    implicitWidth: Services.Theme.popupWidth
    implicitHeight: 2 * Services.Theme.popupPadding + statusRow.height + brightnessRow.height + volumeRow.height + mprisRow.height + tileGrid.height + 4 * Services.Theme.popupSpacing
    PanelNavKeys {
        host: root
        panel: root
        navActive: !(bar.historyPanel?.visible ?? false)
    }
    Shortcut { sequence: "["; enabled: root.visible && !(bar.historyPanel?.visible ?? false); onActivated: root.stepSection(-1) }
    Shortcut { sequence: "]"; enabled: root.visible && !(bar.historyPanel?.visible ?? false); onActivated: root.stepSection(1) }
    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            actionIndex = -1;
            mprisCol = 1;
            root.clampSelection();
            Services.Notifs.suppressToasts = true;
            Services.Notifs.shelveToasts();
        } else {
            Services.Notifs.suppressToasts = false;
            Services.Notifs.flushPending();
        }
    }
    readonly property var mprisPlayer: Services.Media.activePlayer
    readonly property int playerCount: Services.Media.usableCount
    property int selectedIndex: 0
    property int actionIndex: -1
    property int mprisCol: 1
    property var micSource: Services.Media.source
    readonly property var audioSink: Services.Media.sink
    function volumeIdx(): int {
        return Services.Media.brightnessAvailable ? 1 : 0;
    }
    function mprisIdx(): int {
        return root.mprisPlayer !== null ? root.volumeIdx() + 1 : -1;
    }
    function mprisMaxCol(): int {
        return root.playerCount > 1 ? 3 : 2;
    }
    function firstTileIdx(): int {
        return root.volumeIdx() + 1 + (root.mprisPlayer !== null ? 1 : 0);
    }
    function clearIdx(): int {
        return Services.Notifs.history.length > 0 ? root.firstTileIdx() + 9 : -1;
    }
    function firstHistIdx(): int {
        return root.firstTileIdx() + 9 + (Services.Notifs.history.length > 0 ? 1 : 0);
    }
    function itemCount(): int {
        return root.firstHistIdx() + Services.Notifs.history.length;
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
    function selectMpris(col: int): void {
        if (root.mprisPlayer === null)
            return;
        if (selectedIndex === root.mprisIdx() && mprisCol === col)
            return;
        selectedIndex = root.mprisIdx();
        actionIndex = -1;
        mprisCol = Services.Theme.clamp(col, 0, root.mprisMaxCol());
        root.clampSelection();
    }
    Connections {
        target: Services.Notifs
        function onHistoryChanged() {
            root.clampSelection();
            root.revealSelection();
        }
    }
    onMprisPlayerChanged: {
        if (root.visible)
            root.clampSelection();
    }
    function revealSelection(): void {
        const kind = root.selectedKind();
        if (kind === "history")
            bar.revealHistory(root.selectedHistItem());
        else if (kind === "clear")
            bar.revealHistory(0);
    }
    function stepSelection(dir: int): void {
        actionIndex = -1;
        selectedIndex += dir;
        root.clampSelection();
        root.revealSelection();
    }
    function sectionBounds(): var {
        const bounds = [0, root.firstTileIdx()];
        if (root.clearIdx() >= 0)
            bounds.push(root.clearIdx());
        else if (Services.Notifs.history.length > 0)
            bounds.push(root.firstHistIdx());
        return bounds;
    }
    function stepSection(dir: int): void {
        actionIndex = -1;
        const bounds = root.sectionBounds();
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
    function stepVertical(dir: int): void {
        actionIndex = -1;
        if (root.selectedKind() !== "tile") {
            root.stepSelection(dir);
            return;
        }
        const target = selectedIndex + dir * 3;
        if (target < root.firstTileIdx())
            selectedIndex = root.mprisPlayer !== null ? root.mprisIdx() : root.volumeIdx();
        else if (dir > 0 && Services.Notifs.history.length > 0 && target >= root.clearIdx())
            selectedIndex = root.clearIdx();
        else
            selectedIndex = target;
        root.clampSelection();
        root.revealSelection();
    }
    function selectedKind(): string {
        if (Services.Media.brightnessAvailable && selectedIndex === 0)
            return "brightness";
        if (selectedIndex === root.volumeIdx())
            return "volume";
        if (root.mprisPlayer !== null && selectedIndex === root.mprisIdx())
            return "mpris";
        if (Services.Notifs.history.length > 0 && selectedIndex === root.clearIdx())
            return "clear";
        if (selectedIndex >= root.firstHistIdx())
            return "history";
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
    function cycleProfileTile(): void {
        if (Services.Asus.available)
            Services.Asus.cycleProfile(1);
        else
            Services.Power.cycleProfile();
    }
    function adjustSelected(dir: int): void {
        const kind = root.selectedKind();
        if (kind === "brightness")
            Services.Media.setBrightness(Services.Media.brightness + dir * Services.Theme.brightnessStep, true);
        else if (kind === "volume")
            root.adjustVolume(dir * Services.Theme.volumeStep);
        else if (kind === "mpris")
            mprisCol = Services.Theme.clamp(mprisCol + dir, 0, root.mprisMaxCol());
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
        Services.Notifs.dismissHistoryAt(histItem);
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
            root.dismissSelected();
            return;
        }
        try {
            Services.Notifs.activateDefault(live);
        } catch (_) {}
        Services.Notifs.dismissHistoryAt(histItem);
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
        if (kind === "brightness")
            return;
        if (kind === "mpris") {
            root.activateMpris(mprisCol);
            return;
        }
        if (kind === "clear") {
            actionIndex = -1;
            Services.Notifs.clearHistory();
            root.clampSelection();
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
    PopupCard {
        StatusRow {
            id: statusRow
        }
        BrightnessRow {
            id: brightnessRow
            popup: root
        }
        VolumeRow {
            id: volumeRow
            popup: root
        }
        MprisRow {
            id: mprisRow
            popup: root
        }
        TileGrid {
            id: tileGrid
            popup: root
        }
    }
}
