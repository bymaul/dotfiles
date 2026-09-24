import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import "../components"
import "../services" as Services
BasePopup {
    id: root
    property var historyWindow: null
    extraGrabWindows: root.historyWindow != null ? [root.historyWindow] : []
    implicitWidth: Services.Theme.popupWidth
    implicitHeight: (Services.Media.brightnessAvailable ? 258 : 214) + (root.mprisPlayer !== null ? Services.Theme.rowHeight + Services.Theme.popupSpacing : 0)
    PanelNavKeys {
        host: root
        panel: root
    }
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
    property int playerCount: 0
    function refreshPlayer(): void {
        mprisPlayer = Services.Media.activePlayer();
        playerCount = Services.Media.playerCount();
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
    function mprisMaxCol(): int {
        return root.playerCount > 1 ? 3 : 2;
    }
    function firstTileIdx(): int {
        return root.volumeIdx() + 1 + (root.mprisPlayer !== null ? 1 : 0);
    }
    function clearIdx(): int {
        return Services.Notifs.history.length > 0 ? root.firstTileIdx() + 8 : -1;
    }
    function firstHistIdx(): int {
        return root.firstTileIdx() + 8 + (Services.Notifs.history.length > 0 ? 1 : 0);
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
        return item?.live?.actions ?? [];
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
        if (col === 0)
            Services.Media.mediaPrev();
        else if (col === 2)
            Services.Media.mediaNext();
        else if (col === 3) {
            Services.Media.cyclePlayer();
            root.refreshPlayer();
            root.mprisCol = Services.Theme.clamp(root.mprisCol, 0, root.mprisMaxCol());
        } else
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
        const actions = [() => bar.openWifiFromPanel(), () => bar.openBluetoothFromPanel(), () => root.toggleMicMute(), () => Services.Modes.toggleCaffeine(), () => Services.Modes.toggleDnd(), () => Services.Power.cycleProfile(), () => bar.openSettingsFromPanel(), () => bar.openPowerFromPanel()];
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
            height: visible ? Services.Theme.rowHeight : 0
            color: root.selectedIndex === 0 ? Services.Theme.activeBg : Services.Theme.surface
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
                    color: Services.Theme.fg
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px14
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
                    color: Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                }
            }
        }
        Rectangle {
            width: parent.width
            height: Services.Theme.rowHeight
            color: root.selectedIndex === root.volumeIdx() ? Services.Theme.activeBg : Services.Theme.surface
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
                    color: Services.Theme.fg
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px14
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.toggleVolumeMute()
                    }
                }
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 80
                    maximum: Services.Theme.volumeMax
                    wheelStep: Services.Theme.volumeStep
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
                    color: Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                }
            }
        }
        Rectangle {
            id: transportRect
            visible: root.mprisPlayer !== null
            width: parent.width
            height: visible ? Services.Theme.rowHeight : 0
                color: root.selectedKind() === "mpris" ? Services.Theme.activeBg : Services.Theme.surface
                readonly property bool mprisSelected: root.selectedKind() === "mpris"
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onContainsMouseChanged: {
                        if (containsMouse)
                            root.selectMpris(root.mprisCol);
                    }
                }
                Item {
                    id: artBox
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    width: 28
                    height: 28
                    Text {
                        anchors.centerIn: parent
                        visible: artImg.status !== Image.Ready
                        text: "󰝚"
                        color: Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px14
                    }
                    Image {
                        id: artImg
                        anchors.fill: parent
                        visible: status === Image.Ready
                        source: root.mprisPlayer?.trackArtUrl ?? ""
                        asynchronous: true
                        cache: true
                        smooth: true
                        fillMode: Image.PreserveAspectCrop
                    }
                }
                Column {
                    anchors {
                        left: artBox.right
                        right: transportBtns.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 8
                        rightMargin: 8
                    }
                    spacing: 0
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.mprisPlayer?.trackTitle || root.mprisPlayer?.identity || "Unknown"
                        color: Services.Theme.fg
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: {
                            const parts = [root.mprisPlayer?.trackArtist, root.mprisPlayer?.trackAlbum].filter(s => s);
                            return parts.length > 0 ? parts.join(" · ") : (root.mprisPlayer?.identity ?? "");
                        }
                        color: Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px10
                    }
                }
                Row {
                    id: transportBtns
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 10
                    }
                    spacing: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰒮"
                        color: transportRect.mprisSelected && root.mprisCol === 0 ? Services.Theme.accentFg : Services.Theme.fg
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px14
                        Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            visible: transportRect.mprisSelected && root.mprisCol === 0
                            color: Services.Theme.accent
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
                        color: transportRect.mprisSelected && root.mprisCol === 1 ? Services.Theme.accentFg : Services.Theme.fg
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px14
                        Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            visible: transportRect.mprisSelected && root.mprisCol === 1
                            color: Services.Theme.accent
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
                        color: transportRect.mprisSelected && root.mprisCol === 2 ? Services.Theme.accentFg : Services.Theme.fg
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px14
                        Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            visible: transportRect.mprisSelected && root.mprisCol === 2
                            color: Services.Theme.accent
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
                        visible: root.playerCount > 1
                        width: visible ? 34 : 0
                        horizontalAlignment: Text.AlignHCenter
                        text: (Services.Media.playerIndex() + 1) + "/" + root.playerCount
                        color: transportRect.mprisSelected && root.mprisCol === 3 ? Services.Theme.accentFg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px10
                        Rectangle {
                            anchors.centerIn: parent
                            width: 34
                            height: 24
                            visible: transportRect.mprisSelected && root.mprisCol === 3
                            color: Services.Theme.accent
                            z: -1
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: {
                                if (containsMouse)
                                    root.selectMpris(3);
                            }
                            onClicked: root.activateMpris(3)
                        }
                    }
                }
            }
        Grid {
            columns: 3
            columnSpacing: Services.Theme.listSpacing
            rowSpacing: Services.Theme.listSpacing
            width: parent.width
            Tile {
                glyph: Networking.wifiEnabled ? (Services.Wifi.connected ? "󰤨" : "󰤭") : "󰤯"
                label: "Wi-Fi"
                active: Networking.wifiEnabled
                selected: root.selectedIndex === root.firstTileIdx() + 0
                onClicked: bar.openWifiFromPanel()
                onHovered: root.selectIndex(root.firstTileIdx() + 0)
            }
            Tile {
                glyph: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
                label: "Bluetooth"
                active: Bluetooth.defaultAdapter?.enabled ?? false
                available: Bluetooth.defaultAdapter != null
                selected: root.selectedIndex === root.firstTileIdx() + 1
                onClicked: bar.openBluetoothFromPanel()
                onHovered: root.selectIndex(root.firstTileIdx() + 1)
            }
            Tile {
                glyph: root.micSource?.audio?.muted ? "󰍭" : "󰍬"
                label: "Mic"
                active: !(root.micSource?.audio?.muted ?? false)
                available: root.micSource?.audio != null
                selected: root.selectedIndex === root.firstTileIdx() + 2
                onClicked: root.toggleMicMute()
                onHovered: root.selectIndex(root.firstTileIdx() + 2)
            }
            Tile {
                glyph: "󰅶"
                label: "Caffeine"
                active: Services.Modes.caffeineActive
                selected: root.selectedIndex === root.firstTileIdx() + 3
                onClicked: Services.Modes.toggleCaffeine()
                onHovered: root.selectIndex(root.firstTileIdx() + 3)
            }
            Tile {
                glyph: ""
                label: "DND"
                active: Services.Modes.dndActive
                selected: root.selectedIndex === root.firstTileIdx() + 4
                onClicked: Services.Modes.toggleDnd()
                onHovered: root.selectIndex(root.firstTileIdx() + 4)
            }
            Tile {
                glyph: "󰓅"
                label: Services.Power.profilesAvailable && Services.Power.profileName !== "" ? Services.Power.profileName : "Profile"
                active: Services.Power.profileName === "performance"
                available: Services.Power.profilesAvailable
                selected: root.selectedIndex === root.firstTileIdx() + 5
                onClicked: Services.Power.cycleProfile()
                onHovered: root.selectIndex(root.firstTileIdx() + 5)
            }
            Tile {
                glyph: ""
                label: "Settings"
                active: false
                selected: root.selectedIndex === root.firstTileIdx() + 6
                onClicked: bar.openSettingsFromPanel()
                onHovered: root.selectIndex(root.firstTileIdx() + 6)
            }
            Tile {
                glyph: "󰐥"
                label: "Power"
                active: false
                selected: root.selectedIndex === root.firstTileIdx() + 7
                onClicked: bar.openPowerFromPanel()
                onHovered: root.selectIndex(root.firstTileIdx() + 7)
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
