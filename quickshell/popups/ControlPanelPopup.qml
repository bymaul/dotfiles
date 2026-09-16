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
    implicitHeight: (Services.Media.brightnessAvailable ? 258 : 214) + (root.mprisPlayer !== null ? Palette.rowHeight + Palette.popupSpacing : 0) + (Services.Notifs.history.length > 0 ? 12 : 0)
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepVertical(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepVertical(-1) }
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.adjustSelected(-1) }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.adjustSelected(1) }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "m"; enabled: root.visible; onActivated: root.toggleVolumeMute() }
    Shortcut { sequence: "c"; enabled: root.visible && Services.Notifs.history.length > 0; onActivated: Services.Notifs.clearHistory() }
    Shortcut { sequence: "o"; enabled: root.visible && Services.Notifs.history.length > 0; onActivated: root.invokeSelectedAction() }
    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            root.refreshPlayer();
            Services.Notifs.hideAllToasts();
        }
        bar.updateToastSuppress();
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
    property var micSource: Pipewire.defaultAudioSource
    readonly property var audioSink: Services.Media.sink
    function volumeIdx(): int {
        return Services.Media.brightnessAvailable ? 1 : 0;
    }
    function firstTileIdx(): int {
        return root.volumeIdx() + 1;
    }
    function firstHistIdx(): int {
        return root.firstTileIdx() + 7;
    }
    function itemCount(): int {
        return root.firstHistIdx() + Services.Notifs.history.length;
    }
    function clampSelection(): void {
        selectedIndex = Palette.clamp(selectedIndex, 0, root.itemCount() - 1);
    }
    Connections {
        target: Services.Notifs
        function onHistoryChanged() {
            root.clampSelection();
            root.revealSelection();
        }
    }
    function revealSelection(): void {
        if (root.selectedKind() === "history")
            bar.revealHistory(root.selectedHistItem());
    }
    function stepSelection(dir: int): void {
        selectedIndex += dir;
        root.clampSelection();
        root.revealSelection();
    }
    function stepVertical(dir: int): void {
        if (root.selectedKind() !== "tile") {
            root.stepSelection(dir);
            return;
        }
        const target = selectedIndex + dir * 3;
        selectedIndex = target < root.firstTileIdx() ? root.volumeIdx() : target;
        root.clampSelection();
        root.revealSelection();
    }
    function selectedKind(): string {
        if (Services.Media.brightnessAvailable && selectedIndex === 0)
            return "brightness";
        if (selectedIndex === root.volumeIdx())
            return "volume";
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
        else
            root.stepSelection(dir);
    }
    function activateSelected(): void {
        const kind = root.selectedKind();
        if (kind === "volume") {
            root.toggleVolumeMute();
            return;
        }
        if (kind === "brightness")
            return;
        if (kind === "history") {
            Services.Notifs.dismissHistoryAt(root.selectedHistItem());
            root.clampSelection();
            return;
        }
        const actions = [() => bar.openWifiFromPanel(), () => bar.openBluetoothFromPanel(), () => root.toggleMicMute(), () => Services.Modes.toggleCaffeine(), () => Services.Modes.toggleDnd(), () => bar.openSettingsFromPanel(), () => bar.openPowerFromPanel()];
        const tile = root.selectedTile();
        if (tile >= 0 && tile < actions.length)
            actions[tile]();
    }
    function invokeSelectedAction(): void {
        if (root.selectedKind() !== "history")
            return;
        const item = Services.Notifs.history[root.selectedHistItem()] ?? null;
        const live = item?.live ?? null;
        const actions = live?.actions ?? [];
        if (!live || actions.length === 0)
            return;
        Services.Notifs.activateAction(live, actions.find(a => a.identifier === "default") ?? actions[0]);
        root.clampSelection();
        bar.closePopups();
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
            height: Palette.rowHeight
            color: Palette.surface
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
                    color: Palette.fg
                    font.family: Palette.font
                    font.pixelSize: Palette.px14
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Media.mediaPrev()
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: (root.mprisPlayer?.isPlaying ?? false) ? "󰏤" : "󰐊"
                    color: Palette.fg
                    font.family: Palette.font
                    font.pixelSize: Palette.px14
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Media.mediaToggle()
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: "󰒭"
                    color: Palette.fg
                    font.family: Palette.font
                    font.pixelSize: Palette.px14
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Media.mediaNext()
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
            }
            ToggleTile {
                glyph: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
                label: "Bluetooth"
                active: Bluetooth.defaultAdapter?.enabled ?? false
                enabled: Bluetooth.defaultAdapter != null
                selected: root.selectedIndex === root.firstTileIdx() + 1
                onTileClicked: bar.openBluetoothFromPanel()
            }
            ToggleTile {
                glyph: root.micSource?.audio?.muted ? "󰍭" : "󰍬"
                label: "Mic"
                active: !(root.micSource?.audio?.muted ?? false)
                enabled: root.micSource?.audio != null
                selected: root.selectedIndex === root.firstTileIdx() + 2
                onTileClicked: root.toggleMicMute()
            }
            ToggleTile {
                glyph: "󰅶"
                label: "Caffeine"
                active: Services.Modes.caffeineActive
                selected: root.selectedIndex === root.firstTileIdx() + 3
                onTileClicked: Services.Modes.toggleCaffeine()
            }
            ToggleTile {
                glyph: ""
                label: "DND"
                active: Services.Modes.dndActive
                selected: root.selectedIndex === root.firstTileIdx() + 4
                onTileClicked: Services.Modes.toggleDnd()
            }
            ToggleTile {
                glyph: ""
                label: "Settings"
                active: false
                selected: root.selectedIndex === root.firstTileIdx() + 5
                onTileClicked: bar.openSettingsFromPanel()
            }
            ToggleTile {
                glyph: "󰐥"
                label: "Power"
                active: false
                selected: root.selectedIndex === root.firstTileIdx() + 6
                onTileClicked: bar.openPowerFromPanel()
            }
        }
        HintText {
            text: Services.Notifs.history.length > 0 ? "jk move · hl adjust · ↵ activate\nm mute · c clear · o open" : "jk move · hl adjust · ↵ activate · m mute"
        }
    }
}
