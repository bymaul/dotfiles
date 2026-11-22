import QtQuick
import Quickshell
import "../components"
import "../services" as Services
import "control"

BasePopup {
    id: root
    implicitWidth: Services.Theme.popupWidth
    implicitHeight: Services.Theme.popupPadding * 2 + card.contentHeight
    property bool focusInput: false
    property int cursor: 0

    readonly property var sinks: Services.Media.sinks
    readonly property var sources: Services.Media.sources
    readonly property int sinkCount: root.sinks.length
    readonly property int sourceCount: root.sources.length
    readonly property int inVolumeStop: 1 + root.sinkCount
    readonly property int stopCount: 2 + root.sinkCount + root.sourceCount
    readonly property bool onOutVolume: root.cursor === 0
    readonly property bool onInVolume: root.cursor === root.inVolumeStop
    readonly property int outDeviceCursor: root.cursor >= 1 && root.cursor <= root.sinkCount ? root.cursor - 1 : -1
    readonly property int inDeviceCursor: root.cursor > root.inVolumeStop ? root.cursor - root.inVolumeStop - 1 : -1
    readonly property bool outMuted: Services.Media.sink?.audio?.muted ?? false
    readonly property bool inMuted: Services.Media.source?.audio?.muted ?? false

    function listHeight(count: int): int {
        if (count <= 0)
            return Services.Theme.rowHeight;
        const n = Math.min(count, 4);
        return n * Services.Theme.listRowHeight + (n - 1) * Services.Theme.listSpacing;
    }
    function deviceIsDefault(node): bool {
        if (!node)
            return false;
        const current = node.isSink ? Services.Media.sink : Services.Media.source;
        return !!current && current.id === node.id;
    }
    function moveCursor(dir: int): void {
        if (root.stopCount <= 0)
            return;
        root.cursor = Services.Theme.clamp(root.cursor + dir, 0, root.stopCount - 1);
        root.revealCursor();
    }
    function revealCursor(): void {
        if (root.outDeviceCursor >= 0)
            outList.positionViewAtIndex(root.outDeviceCursor, ListView.Contain);
        if (root.inDeviceCursor >= 0)
            inList.positionViewAtIndex(root.inDeviceCursor, ListView.Contain);
    }
    function adjust(dir: int): void {
        if (root.onOutVolume)
            Services.Media.adjustVolume(dir * Services.Theme.volumeStep, true);
        else if (root.onInVolume)
            Services.Media.adjustMicVolume(dir * Services.Theme.volumeStep, true);
    }
    function activate(): void {
        if (root.onOutVolume) {
            root.toggleOutMute();
            return;
        }
        if (root.onInVolume) {
            root.toggleInMute();
            return;
        }
        if (root.outDeviceCursor >= 0) {
            const node = root.sinks[root.outDeviceCursor];
            if (node)
                Services.Media.setSink(node);
            return;
        }
        if (root.inDeviceCursor >= 0) {
            const node = root.sources[root.inDeviceCursor];
            if (node)
                Services.Media.setSource(node);
        }
    }
    function selectOutDevice(index: int): void {
        root.cursor = index + 1;
        root.activate();
    }
    function selectInDevice(index: int): void {
        root.cursor = root.inVolumeStop + 1 + index;
        root.activate();
    }
    function toggleOutMute(): void {
        Services.Media.toggleVolumeMute(true);
    }
    function toggleInMute(): void {
        Services.Media.toggleMicMute(true);
    }
    onVisibleChanged: {
        if (visible && !wasVisible) {
            root.cursor = root.focusInput ? root.inVolumeStop : 0;
            Qt.callLater(root.revealCursor);
        }
    }
    onStopCountChanged: {
        if (root.cursor >= root.stopCount)
            root.cursor = Math.max(0, root.stopCount - 1);
    }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.moveCursor(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.moveCursor(-1) }
    Shortcut { sequence: "Down"; enabled: root.visible; onActivated: root.moveCursor(1) }
    Shortcut { sequence: "Up"; enabled: root.visible; onActivated: root.moveCursor(-1) }
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.adjust(-1) }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.adjust(1) }
    Shortcut { sequence: "Left"; enabled: root.visible; onActivated: root.adjust(-1) }
    Shortcut { sequence: "Right"; enabled: root.visible; onActivated: root.adjust(1) }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.activate() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.activate() }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.activate() }
    Shortcut { sequence: "m"; enabled: root.visible; onActivated: root.toggleOutMute() }
    Shortcut { sequence: "Shift+M"; enabled: root.visible; onActivated: root.toggleInMute() }

    PopupCard {
        id: card
        Text {
            width: parent.width
            text: "  Output"
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px10
        }
        SliderRow {
            popup: null
            selected: root.onOutVolume
            glyph: root.outMuted ? "󰝟" : "󰕾"
            sliderMaximum: Services.Theme.volumeMax
            sliderStep: Services.Theme.volumeStep
            sliderValue: Services.Media.sink?.audio?.volume ?? 0
            valueLabel: Math.round((Services.Media.sink?.audio?.volume ?? 0) * 100) + "%"
            onSliderMoved: value => {
                const audio = Services.Media.sink?.audio;
                if (audio)
                    audio.volume = value;
            }
            onGlyphClicked: root.toggleOutMute()
        }
        Item {
            width: parent.width
            height: root.listHeight(root.sinkCount)
            ListView {
                id: outList
                anchors.fill: parent
                clip: true
                spacing: Services.Theme.listSpacing
                model: root.sinks
                delegate: ResultRow {
                    id: outRow
                    required property var modelData
                    required property int index
                    selected: root.outDeviceCursor === index
                    highlighted: root.deviceIsDefault(modelData)
                    rowHeight: Services.Theme.listRowHeight
                    onClicked: root.selectOutDevice(index)
                    DeviceRow {
                        selected: outRow.selected
                        hovered: outRow.isHovered
                        accented: root.deviceIsDefault(modelData)
                        glyph: "󰓃"
                        title: Services.Media.deviceLabel(modelData)
                        subtitle: root.deviceIsDefault(modelData) ? "Default" : "Available"
                        reserveRight: 56
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            text: "✓"
                            visible: root.deviceIsDefault(modelData)
                            color: outRow.selected ? Services.Theme.accentFg : Services.Theme.accent
                            font.family: Services.Theme.font
                            font.pixelSize: Services.Theme.px12
                        }
                    }
                }
            }
            EmptyStateText {
                visible: root.sinkCount === 0
                text: "No output devices"
            }
        }
        Text {
            width: parent.width
            text: "  Input"
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px10
        }
        SliderRow {
            popup: null
            selected: root.onInVolume
            glyph: root.inMuted ? "󰍭" : "󰍬"
            sliderMaximum: Services.Theme.volumeMax
            sliderStep: Services.Theme.volumeStep
            sliderValue: Services.Media.source?.audio?.volume ?? 0
            valueLabel: Math.round((Services.Media.source?.audio?.volume ?? 0) * 100) + "%"
            onSliderMoved: value => {
                const audio = Services.Media.source?.audio;
                if (audio)
                    audio.volume = value;
            }
            onGlyphClicked: root.toggleInMute()
        }
        Item {
            width: parent.width
            height: root.listHeight(root.sourceCount)
            ListView {
                id: inList
                anchors.fill: parent
                clip: true
                spacing: Services.Theme.listSpacing
                model: root.sources
                delegate: ResultRow {
                    id: inRow
                    required property var modelData
                    required property int index
                    selected: root.inDeviceCursor === index
                    highlighted: root.deviceIsDefault(modelData)
                    rowHeight: Services.Theme.listRowHeight
                    onClicked: root.selectInDevice(index)
                    DeviceRow {
                        selected: inRow.selected
                        hovered: inRow.isHovered
                        accented: root.deviceIsDefault(modelData)
                        glyph: "󰍬"
                        title: Services.Media.deviceLabel(modelData)
                        subtitle: root.deviceIsDefault(modelData) ? "Default" : "Available"
                        reserveRight: 56
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            text: "✓"
                            visible: root.deviceIsDefault(modelData)
                            color: inRow.selected ? Services.Theme.accentFg : Services.Theme.accent
                            font.family: Services.Theme.font
                            font.pixelSize: Services.Theme.px12
                        }
                    }
                }
            }
            EmptyStateText {
                visible: root.sourceCount === 0
                text: "No input devices"
            }
        }
        HintText {
            text: "m mute · M mic"
        }
    }
}
