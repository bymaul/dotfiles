import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import "../components"
import "../services" as Services
import "../Palette.js" as Palette
BasePopup {
    id: root
    useGrab: false
    implicitWidth: Palette.popupWidth
    implicitHeight: (Services.Media.brightnessAvailable ? 258 : 214) + (root.mprisPlayer !== null ? Palette.rowHeight + Palette.popupSpacing : 0)
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }
    Shortcut {
        sequence: "q"
        enabled: root.visible
        onActivated: root.close()
    }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepVertical(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepVertical(-1) }
    Shortcut { sequence: "Down"; enabled: root.visible; onActivated: root.stepVertical(1) }
    Shortcut { sequence: "Up"; enabled: root.visible; onActivated: root.stepVertical(-1) }
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.adjustSelected(-1) }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.adjustSelected(1) }
    Shortcut { sequence: "Left"; enabled: root.visible; onActivated: root.adjustSelected(-1) }
    Shortcut { sequence: "Right"; enabled: root.visible; onActivated: root.adjustSelected(1) }
    Shortcut { sequence: "Tab"; enabled: root.visible; onActivated: root.focusNext() }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible; onActivated: root.focusPrev() }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "m"; enabled: root.visible; onActivated: root.toggleVolumeMute() }
    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            actionIndex = -1;
            mprisCol = 1;
            root.refreshPlayer();
            root.clampSelection();
            Services.Notifs.suppressToasts = true;
            Services.Notifs.shelveToasts();
        } else {
            Services.Notifs.suppressToasts = false;
            Services.Notifs.flushPending();
        }
    }
    property var mprisPlayer: null
    function refreshPlayer(): void {
        mprisPlayer = Services.Media.activePlayer();
    }
    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        onTriggered: root.refreshPlayer()
    }
    property int selectedIndex: 0
    property int actionIndex: -1
    property int mprisCol: 1
    property var micSource: Pipewire.defaultAudioSource
    readonly property var audioSink: Services.Media.sink
    function volumeIdx(): int {
        return Services.Media.brightnessAvailable ? 1 : 0;
    }
    function mprisIdx(): int {
        return root.mprisPlayer !== null ? root.volumeIdx() + 1 : -1;
    }
    function firstTileIdx(): int {
        return root.volumeIdx() + 1 + (root.mprisPlayer !== null ? 1 : 0);
    }
    function clearIdx(): int {
        return Services.Notifs.history.length > 0 ? root.firstTileIdx() + 7 : -1;
    }
    function firstHistIdx(): int {
        return root.firstTileIdx() + 7 + (Services.Notifs.history.length > 0 ? 1 : 0);
    }
    function itemCount(): int {
        return root.firstHistIdx() + Services.Notifs.history.length;
    }
    function clampSelection(): void {
        selectedIndex = Palette.clamp(selectedIndex, 0, root.itemCount() - 1);
        root.clampAction();
    }
    function selectedActions(): var {
        if (root.selectedKind() !== "history")
            return [];
        const item = Services.Notifs.history[root.selectedHistItem()] ?? null;
        return item?.live?.actions ?? [];
    }
    function actionCount(): int {
        return root.selectedActions().length;
    }
    function clampAction(): void {
        if (root.selectedKind() !== "history" || root.actionCount() === 0)
            actionIndex = -1;
        else
            actionIndex = Palette.clamp(actionIndex, -1, root.actionCount() - 1);
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
        mprisCol = Palette.clamp(col, 0, 2);
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
        const audio = root.audioSink?.audio;
        if (audio)
            audio.volume = Palette.clamp(audio.volume + delta, 0, Palette.volumeMax);
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
    function adjustSelected(dir: int): void {
        const kind = root.selectedKind();
        if (kind === "brightness")
            Services.Media.setBrightness(Services.Media.brightness + dir * Palette.brightnessStep, true);
        else if (kind === "volume")
            root.adjustVolume(dir * Palette.volumeStep);
        else if (kind === "mpris")
            mprisCol = Palette.clamp(mprisCol + dir, 0, 2);
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
        if (col === 0)
            Services.Media.mediaPrev();
        else if (col === 2)
            Services.Media.mediaNext();
        else
            Services.Media.mediaToggle();
    }
    function activateActionAt(actIdx: int): void {
        const histItem = root.selectedHistItem();
        const item = Services.Notifs.history[histItem] ?? null;
        const live = item?.live ?? null;
        const actions = live?.actions ?? [];
        if (!live || actIdx < 0 || actIdx >= actions.length)
            return;
        Services.Notifs.activateAction(live, actions[actIdx]);
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
        const actions = root.selectedActions();
        if (actions.length === 0) {
            root.dismissSelected();
            return;
        }
        let idx = actions.findIndex(a => a.identifier === "default");
        if (idx < 0)
            idx = 0;
        root.activateActionAt(idx);
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
        const actions = [() => bar.openWifiFromPanel(), () => bar.openBluetoothFromPanel(), () => root.toggleMicMute(), () => Services.Modes.toggleCaffeine(), () => Services.Modes.toggleDnd(), () => bar.openSettingsFromPanel(), () => bar.openPowerFromPanel()];
        const tile = root.selectedTile();
        if (tile >= 0 && tile < actions.length)
            actions[tile]();
    }
    PwObjectTracker {
        objects: [root.micSource]
    }
    PopupCard {
        Rectangle {
            visible: Services.Media.brightnessAvailable
            width: parent.width
            height: visible ? Palette.rowHeight : 0
            color: root.selectedIndex === 0 ? Palette.activeBg : Palette.surface
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onContainsMouseChanged: {
                    if (containsMouse)
                        root.selectIndex(0);
                }
            }
            Row {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                spacing: 10
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    text: "󰃟"
                    color: Palette.fg
                    font.family: Palette.font
                    font.pixelSize: Palette.px14
                }
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 80
                    value: Services.Media.brightness / 100
                    onSliderMoved: value => Services.Media.setBrightness(value * 100, true)
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Services.Media.brightness) + "%"
                    color: Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                }
            }
        }
        Rectangle {
            width: parent.width
            height: Palette.rowHeight
            color: root.selectedIndex === root.volumeIdx() ? Palette.activeBg : Palette.surface
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onContainsMouseChanged: {
                    if (containsMouse)
                        root.selectIndex(root.volumeIdx());
                }
            }
            Row {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                spacing: 10
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    text: root.audioSink?.audio?.muted ? "󰝟" : "󰕾"
                    color: Palette.fg
                    font.family: Palette.font
                    font.pixelSize: Palette.px14
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.toggleVolumeMute()
                    }
                }
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 80
                    maximum: Palette.volumeMax
                    value: root.audioSink?.audio?.volume ?? 0
                    onSliderMoved: value => {
                        const audio = root.audioSink?.audio;
                        if (audio)
                            audio.volume = value;
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    horizontalAlignment: Text.AlignRight
                    text: Math.round((root.audioSink?.audio?.volume ?? 0) * 100) + "%"
                    color: Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                }
            }
        }
        Rectangle {
            visible: root.mprisPlayer !== null
            width: parent.width
            height: visible ? Palette.rowHeight : 0
            color: root.selectedKind() === "mpris" ? Palette.activeBg : Palette.surface
            readonly property bool mprisSelected: root.selectedKind() === "mpris"
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onContainsMouseChanged: {
                    if (containsMouse)
                        root.selectMpris(root.mprisCol);
                }
            }
            Row {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: "󰒮"
                    color: parent.parent.mprisSelected && root.mprisCol === 0 ? Palette.onAccent : Palette.fg
                    font.family: Palette.font
                    font.pixelSize: Palette.px14
                    Rectangle {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        radius: 4
                        visible: parent.parent.parent.mprisSelected && root.mprisCol === 0
                        color: Palette.accent
                        z: -1
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.selectMpris(0);
                        }
                        onClicked: root.activateMpris(0)
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: (root.mprisPlayer?.isPlaying ?? false) ? "󰏤" : "󰐊"
                    color: parent.parent.mprisSelected && root.mprisCol === 1 ? Palette.onAccent : Palette.fg
                    font.family: Palette.font
                    font.pixelSize: Palette.px14
                    Rectangle {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        radius: 4
                        visible: parent.parent.parent.mprisSelected && root.mprisCol === 1
                        color: Palette.accent
                        z: -1
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.selectMpris(1);
                        }
                        onClicked: root.activateMpris(1)
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: "󰒭"
                    color: parent.parent.mprisSelected && root.mprisCol === 2 ? Palette.onAccent : Palette.fg
                    font.family: Palette.font
                    font.pixelSize: Palette.px14
                    Rectangle {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        radius: 4
                        visible: parent.parent.parent.mprisSelected && root.mprisCol === 2
                        color: Palette.accent
                        z: -1
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.selectMpris(2);
                        }
                        onClicked: root.activateMpris(2)
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 78
                    elide: Text.ElideRight
                    text: (root.mprisPlayer?.trackTitle || root.mprisPlayer?.identity || "Unknown") + (root.mprisPlayer?.trackArtist ? " - " + root.mprisPlayer.trackArtist : "")
                    color: Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                }
            }
        }
        Grid {
            columns: 3
            columnSpacing: Palette.listSpacing
            rowSpacing: Palette.listSpacing
            width: parent.width
            ToggleTile {
                glyph: Networking.wifiEnabled ? (bar.connectedWifi ? "󰤨" : "󰤭") : "󰤯"
                label: "Wi-Fi"
                active: Networking.wifiEnabled
                selected: root.selectedIndex === root.firstTileIdx() + 0
                onTileClicked: bar.openWifiFromPanel()
                onHovered: root.selectIndex(root.firstTileIdx() + 0)
            }
            ToggleTile {
                glyph: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
                label: "Bluetooth"
                active: Bluetooth.defaultAdapter?.enabled ?? false
                enabled: Bluetooth.defaultAdapter != null
                selected: root.selectedIndex === root.firstTileIdx() + 1
                onTileClicked: bar.openBluetoothFromPanel()
                onHovered: root.selectIndex(root.firstTileIdx() + 1)
            }
            ToggleTile {
                glyph: root.micSource?.audio?.muted ? "󰍭" : "󰍬"
                label: "Mic"
                active: !(root.micSource?.audio?.muted ?? false)
                enabled: root.micSource?.audio != null
                selected: root.selectedIndex === root.firstTileIdx() + 2
                onTileClicked: root.toggleMicMute()
                onHovered: root.selectIndex(root.firstTileIdx() + 2)
            }
            ToggleTile {
                glyph: "󰅶"
                label: "Caffeine"
                active: Services.Modes.caffeineActive
                selected: root.selectedIndex === root.firstTileIdx() + 3
                onTileClicked: Services.Modes.toggleCaffeine()
                onHovered: root.selectIndex(root.firstTileIdx() + 3)
            }
            ToggleTile {
                glyph: ""
                label: "DND"
                active: Services.Modes.dndActive
                selected: root.selectedIndex === root.firstTileIdx() + 4
                onTileClicked: Services.Modes.toggleDnd()
                onHovered: root.selectIndex(root.firstTileIdx() + 4)
            }
            ToggleTile {
                glyph: ""
                label: "Settings"
                active: false
                selected: root.selectedIndex === root.firstTileIdx() + 5
                onTileClicked: bar.openSettingsFromPanel()
                onHovered: root.selectIndex(root.firstTileIdx() + 5)
            }
            ToggleTile {
                glyph: "󰐥"
                label: "Power"
                active: false
                selected: root.selectedIndex === root.firstTileIdx() + 6
                onTileClicked: bar.openPowerFromPanel()
                onHovered: root.selectIndex(root.firstTileIdx() + 6)
            }
        }
        HintText {
            text: {
                if (Services.Notifs.history.length === 0)
                    return "jk move · hl adjust · ↵ select · m mute";
                return "jk move · hl adjust · Tab actions · ↵ open · m mute";
            }
        }
    }
}
