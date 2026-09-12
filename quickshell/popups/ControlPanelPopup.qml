import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import "../components"
import "../services" as Services
import "../Palette.js" as Palette

BasePopup {
    id: controlPanel

    required property var volumeControl

    // Covered by the bar-level grab (see shell.qml), which whitelists
    // both this panel and the history companion: a grab owned here
    // would read clicks on the companion as outside clicks and close
    // everything.
    useGrab: false

    implicitWidth: Palette.popupWidth

    // History renders in the companion NotificationHistoryPopup
    // below, so the panel itself stays fixed height.
    implicitHeight: (Services.Media.brightnessAvailable ? 212 : 168) +
        (Services.Notifs.history.length > 0 ? 12 : 0)

    Shortcut {
        sequence: "Escape"
        onActivated: bar.closePopups()
    }

    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0

            // A newly opened panel maps above anything already on
            // screen: retire live cards into history first, or
            // long-lived toasts end up buried under the new window.
            Services.Notifs.hideAllToasts()
        }

        // While open, history is on screen: live cards would only
        // ghost under it, so the server holds new arrivals for
        // history instead of popping them. On close, whatever
        // arrived pops retroactively.
        Services.Notifs.suppressToasts = visible

        if (!visible)
            Services.Notifs.flushPending()
    }

    // ---- keyboard navigation ----
    // items: [brightness?] + [volume] + 6 tiles (wifi, bt, mic,
    // caffeine, dnd, power) + history rows (0..n)
    property int selectedIndex: 0

    function volumeIdx(): int {
        return Services.Media.brightnessAvailable ? 1 : 0
    }

    function firstTileIdx(): int {
        return controlPanel.volumeIdx() + 1
    }

    function firstHistIdx(): int {
        return controlPanel.firstTileIdx() + 6
    }

    function itemCount(): int {
        return controlPanel.firstHistIdx() + Services.Notifs.history.length
    }

    function clampSelection(): void {
        selectedIndex = Math.max(0,
            Math.min(controlPanel.itemCount() - 1, selectedIndex))
    }

    // History can shrink under us (clear/dismiss from the companion
    // window or a sync replace): keep the cursor in range so Enter
    // can't address a stale row.
    Connections {
        target: Services.Notifs

        function onHistoryChanged() {
            controlPanel.clampSelection()
            controlPanel.revealSelection()
        }
    }

    function revealSelection(): void {
        // Rows render in the companion window; ask the bar to scroll
        // it (cross-file ids are invisible here).
        if (controlPanel.selectedKind() === "history")
            bar.revealHistory(controlPanel.selectedHistItem())
    }

    function stepSelection(dir: int): void {
        selectedIndex += dir
        controlPanel.clampSelection()
        controlPanel.revealSelection()
    }

    // Grid is 3 columns: vertical moves jump rows (±3) on tiles,
    // single steps on sliders. Leaving the grid upward lands on
    // the last slider; Down from the tiles enters the history list
    // and clamping handles the bottom edge.
    function stepVertical(dir: int): void {
        if (controlPanel.selectedKind() !== "tile") {
            controlPanel.stepSelection(dir)
            return
        }

        const target = selectedIndex + dir * 3

        if (target < controlPanel.firstTileIdx())
            selectedIndex = controlPanel.volumeIdx()
        else
            selectedIndex = target

        controlPanel.clampSelection()
        controlPanel.revealSelection()
    }

    function selectedKind(): string {
        if (Services.Media.brightnessAvailable && selectedIndex === 0)
            return "brightness"

        if (selectedIndex === controlPanel.volumeIdx())
            return "volume"

        if (selectedIndex >= controlPanel.firstHistIdx())
            return "history"

        return "tile"
    }

    function selectedTile(): int {
        return selectedIndex - controlPanel.firstTileIdx()
    }

    function selectedHistItem(): int {
        return selectedIndex - controlPanel.firstHistIdx()
    }

    function adjustVolume(delta: real): void {
        const audio = volumeControl.sink?.audio

        if (audio)
            audio.volume = Math.max(0, Math.min(1.5, audio.volume + delta))
    }

    function toggleVolumeMute(): void {
        const audio = volumeControl.sink?.audio

        if (audio)
            audio.muted = !audio.muted
    }

    function toggleMicMute(): void {
        const audio = controlPanel.micSource?.audio

        if (audio)
            audio.muted = !audio.muted
    }

    function adjustSelected(dir: int): void {
        const kind = controlPanel.selectedKind()

        if (kind === "brightness")
            Services.Media.setBrightness(Services.Media.brightness + dir * 5, true)
        else if (kind === "volume")
            controlPanel.adjustVolume(dir * 0.05)
        else
            controlPanel.stepSelection(dir)
    }

    function activateSelected(): void {
        const kind = controlPanel.selectedKind()

        if (kind === "volume") {
            controlPanel.toggleVolumeMute()
            return
        }

        if (kind === "brightness")
            return

        // History rows: Enter removes the entry.
        if (kind === "history") {
            Services.Notifs.dismissHistoryAt(controlPanel.selectedHistItem())
            controlPanel.clampSelection()
            return
        }

        const tileActions = [
            () => bar.toggleWifi(),
            () => bar.toggleBluetooth(),
            () => controlPanel.toggleMicMute(),
            () => Services.Modes.toggleCaffeine(),
            () => Services.Modes.toggleDnd(),
            () => bar.togglePower()
        ]

        tileActions[controlPanel.selectedTile()]()
    }

    // Runs the selected history row's primary action button
    // (default id, else first). Rows without actions do nothing;
    // Enter stays the dismiss key.
    function invokeSelectedAction(): void {
        if (controlPanel.selectedKind() !== "history")
            return

        const item = Services.Notifs.history[controlPanel.selectedHistItem()] ?? null
        const live = item?.live ?? null
        const actions = live?.actions ?? []

        if (!live || actions.length === 0)
            return

        const def = actions.find(a => a.identifier === "default") ?? actions[0]

        Services.Notifs.activateAction(live, def)
        controlPanel.clampSelection()
        bar.closePopups()
    }

    // Letter shortcuts stay scoped to the open panel so they never
    // leak into typing elsewhere.
    Shortcut {
        sequence: "j"
        enabled: controlPanel.visible
        onActivated: controlPanel.stepVertical(1)
    }
    Shortcut {
        sequence: "k"
        enabled: controlPanel.visible
        onActivated: controlPanel.stepVertical(-1)
    }
    Shortcut {
        sequence: "h"
        enabled: controlPanel.visible
        onActivated: controlPanel.adjustSelected(-1)
    }
    Shortcut {
        sequence: "l"
        enabled: controlPanel.visible
        onActivated: controlPanel.adjustSelected(1)
    }
    Shortcut {
        sequence: "Return"
        enabled: controlPanel.visible
        onActivated: controlPanel.activateSelected()
    }
    Shortcut {
        sequence: "Enter"
        enabled: controlPanel.visible
        onActivated: controlPanel.activateSelected()
    }
    Shortcut {
        sequence: "Space"
        enabled: controlPanel.visible
        onActivated: controlPanel.activateSelected()
    }
    Shortcut {
        sequence: "m"
        enabled: controlPanel.visible
        onActivated: controlPanel.toggleVolumeMute()
    }
    Shortcut {
        sequence: "c"
        enabled: controlPanel.visible &&
            Services.Notifs.history.length > 0
        onActivated: Services.Notifs.clearHistory()
    }
    Shortcut {
        sequence: "o"
        enabled: controlPanel.visible &&
            Services.Notifs.history.length > 0
        onActivated: controlPanel.invokeSelectedAction()
    }

    property var micSource: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [controlPanel.micSource]
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
                id: brightnessRow

                visible: Services.Media.brightnessAvailable

                width: parent.width
                height: visible ? Palette.rowHeight : 0

                radius: 0

                color: Palette.surface
                border.width: controlPanel.selectedIndex === 0 ? 1 : 0
                border.color: controlPanel.selectedIndex === 0
                    ? Palette.accent : Palette.dim

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

                        font.family:
                            Palette.font

                        font.pixelSize: Palette.px14
                    }

                    SliderBar {
                        anchors.verticalCenter: parent.verticalCenter

                        width: parent.width - 80

                        value: Services.Media.brightness / 100

                        onSliderMoved: value => {
                            Services.Media.setBrightness(value * 100, true)
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        width: 36

                        horizontalAlignment: Text.AlignRight

                        text: Math.round(Services.Media.brightness) + "%"

                        color: Palette.dim

                        font.family:
                            Palette.font

                        font.pixelSize: Palette.px12
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: Palette.rowHeight

                radius: 0

                color: Palette.surface
                border.width: controlPanel.selectedIndex === controlPanel.volumeIdx() ? 1 : 0
                border.color: controlPanel.selectedIndex === controlPanel.volumeIdx()
                    ? Palette.accent : Palette.dim

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

                        text: volumeControl.sink?.audio?.muted
                            ? "󰝟"
                            : "󰕾"

                        color: Palette.fg

                        font.family:
                            Palette.font

                        font.pixelSize: Palette.px14

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                controlPanel.toggleVolumeMute()
                            }
                        }
                    }

                    SliderBar {
                        anchors.verticalCenter: parent.verticalCenter

                        width: parent.width - 80

                        maximum: 1.5

                        value:
                            volumeControl.sink?.audio?.volume ?? 0

                        onSliderMoved: value => {
                            const audio =
                                volumeControl.sink?.audio

                            if (audio)
                                audio.volume = value
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        width: 36

                        horizontalAlignment: Text.AlignRight

                        text: Math.round(
                            (volumeControl.sink?.audio?.volume ?? 0)
                            * 100) + "%"

                        color: Palette.dim

                        font.family:
                            Palette.font

                        font.pixelSize: Palette.px12
                    }
                }
            }

            Grid {
                columns: 3
                columnSpacing: 4
                rowSpacing: 4

                width: parent.width

                ToggleTile {
                    glyph: Networking.wifiEnabled
                        ? (bar.connectedWifi ? "󰤨" : "󰤭")
                        : "󰤯"

                    label: "Wi-Fi"

                    active: Networking.wifiEnabled

                    selected: controlPanel.selectedIndex === controlPanel.firstTileIdx() + 0

                    onTileClicked: {
                        bar.toggleWifi()
                    }
                }

                ToggleTile {
                    glyph:
                        Bluetooth.defaultAdapter?.enabled
                        ? "󰂯" : "󰂲"

                    label: "Bluetooth"

                    active:
                        Bluetooth.defaultAdapter?.enabled ??
                        false

                    enabled: Bluetooth.defaultAdapter != null

                    selected: controlPanel.selectedIndex === controlPanel.firstTileIdx() + 1

                    onTileClicked: {
                        bar.toggleBluetooth()
                    }
                }

                ToggleTile {
                    glyph:
                        controlPanel.micSource?.audio?.muted
                        ? "󰍭" : "󰍬"

                    label: "Mic"

                    active: !(controlPanel.micSource?.audio?.muted ??
                        false)

                    enabled: controlPanel.micSource?.audio != null

                    selected: controlPanel.selectedIndex === controlPanel.firstTileIdx() + 2

                    onTileClicked: {
                        controlPanel.toggleMicMute()
                    }
                }

                ToggleTile {
                    glyph: ""

                    label: "Caffeine"

                    active: Services.Modes.caffeineActive

                    selected: controlPanel.selectedIndex === controlPanel.firstTileIdx() + 3

                    onTileClicked: {
                        Services.Modes.toggleCaffeine()
                    }
                }

                ToggleTile {
                    glyph: ""

                    label: "DND"

                    active: Services.Modes.dndActive

                    selected: controlPanel.selectedIndex === controlPanel.firstTileIdx() + 4

                    onTileClicked: {
                        Services.Modes.toggleDnd()
                    }
                }

                ToggleTile {
                    glyph: "󰐥"

                    label: "Power"

                    active: false

                    selected: controlPanel.selectedIndex === controlPanel.firstTileIdx() + 5

                    onTileClicked: {
                        bar.togglePower()
                    }
                }
            }

            Text {
                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                text: Services.Notifs.history.length > 0
                    ? "jk move · hl adjust · ↵ activate\nm mute · c clear · o open"
                    : "jk move · hl adjust · ↵ activate · m mute"

                wrapMode: Text.WordWrap

                color: Palette.dim

                font.family: Palette.font
                font.pixelSize: Palette.px10
            }
        }
    }
}
