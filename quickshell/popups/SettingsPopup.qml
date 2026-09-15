import QtQuick
import "../components"
import "../services" as Services
import "../Palette.js" as Palette

BasePopup {
    id: root
    implicitWidth: Palette.settingsWidth
    implicitHeight: 16 + tabRow.height + Palette.popupSpacing + root.contentHeight() + Palette.popupSpacing + hint.implicitHeight
    property int tab: 0

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.close()
    }
    Shortcut { sequence: "1"; enabled: root.visible; onActivated: root.tab = 0 }
    Shortcut { sequence: "2"; enabled: root.visible; onActivated: root.tab = 1 }
    Shortcut { sequence: "3"; enabled: root.visible; onActivated: root.tab = 2 }
    Shortcut { sequence: "4"; enabled: root.visible; onActivated: root.tab = 3 }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.adjustSelected(-1) }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.adjustSelected(1) }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.activateSelected() }

    Connections {
        target: Services.Settings
        function onLastApplyMsgChanged(): void {
            if (!root.preventClose)
                return;
            root.regrab();
            settleTimer.restart();
        }
    }
    Timer {
        id: keepGrabTimer
        interval: 200
        repeat: true
        running: root.preventClose && root.visible && root.tab === 3
        onTriggered: root.regrab()
    }
    Timer {
        id: settleTimer
        interval: 1500
        repeat: false
        onTriggered: {
            root.preventClose = false;
            if (root.visible && root.tab === 3)
                root.regrab();
        }
    }

    property int selectedIndex: 0
    onTabChanged: {
        root.selectedIndex = 0;
        root.syncWallCursor();
    }
    onWpCountChanged: root.syncWallCursor()
    onMonCountChanged: root.clampSelection()

    onVisibleChanged: {
        if (visible) {
            root.selectedIndex = 0;
            root.syncWallCursor();
            Services.Settings.refreshWallpapers();
            Services.Settings.refreshMonitors();
        } else {
            root.preventClose = false;
            settleTimer.stop();
        }
    }

    function beginMonitorChange(): void {
        root.preventClose = true;
        settleTimer.restart();
    }
    function itemCount(): int {
        if (root.tab === 0)
            return root.wpCount + 1;
        if (root.tab === 1)
            return 6;
        if (root.tab === 2)
            return 4;
        return root.monCount * 3;
    }
    function clampSelection(): void {
        selectedIndex = Palette.clamp(selectedIndex, 0, Math.max(0, root.itemCount() - 1));
    }
    function syncWallCursor(): void {
        root.clampSelection();
        if (root.tab === 0 && selectedIndex >= 1 && selectedIndex <= root.wpCount)
            wallList.currentIndex = selectedIndex - 1;
        else
            wallList.currentIndex = -1;
    }
    function stepSelection(dir: int): void {
        selectedIndex += dir;
        root.syncWallCursor();
    }
    function monitorNameAt(i: int): string {
        const m = Services.Settings.monitors[Math.floor(i / 3)] ?? null;
        return m && typeof m.name === "string" ? m.name : "";
    }
    function adjustSelected(dir: int): void {
        if (root.tab === 0) {
            root.stepSelection(dir);
            return;
        }
        if (root.tab === 1) {
            switch (selectedIndex) {
            case 0: Services.Settings.setBlurEnabled(!Services.Settings.blurEnabled); break;
            case 1: Services.Settings.setTransparentFx(!Services.Settings.transparentFx); break;
            case 2: Services.Settings.setAnimEnabled(!Services.Settings.animEnabled); break;
            case 3: Services.Settings.setSensitivity(Services.Settings.sensitivity + dir * 0.1); break;
            case 4: Services.Settings.setTouchScroll(Services.Settings.touchScroll + dir * 0.1); break;
            case 5: Services.Settings.setNaturalScroll(!Services.Settings.naturalScroll); break;
            }
            return;
        }
        if (root.tab === 2) {
            switch (selectedIndex) {
            case 0: Services.Settings.setDimTimeout(Services.Settings.dimTimeout + dir * 30); break;
            case 1: Services.Settings.setLockTimeout(Services.Settings.lockTimeout + dir * 60); break;
            case 2: Services.Settings.setScreenOffTimeout(Services.Settings.screenOffTimeout + dir * 60); break;
            case 3: Services.Settings.setSuspendTimeout(Services.Settings.suspendTimeout + dir * 300); break;
            }
            return;
        }
        const name = root.monitorNameAt(selectedIndex);
        if (name === "")
            return;
        root.beginMonitorChange();
        const kind = selectedIndex % 3;
        if (kind === 0)
            Services.Settings.setMonitorEnabled(name, !Services.Settings.monitorEnabled(name));
        else if (kind === 1)
            Services.Settings.setMonitorScale(name, Services.Settings.monitorScale(name) + dir * 0.05);
        else
            Services.Settings.cycleMonitorRes(name, dir);
    }
    function activateSelected(): void {
        if (root.tab === 0) {
            if (selectedIndex === 0)
                Services.Settings.setWallpaper("");
            else if (selectedIndex <= root.wpCount)
                Services.Settings.setWallpaper(Services.Settings.wallpapers[selectedIndex - 1] ?? "");
            return;
        }
        if (root.tab === 1) {
            if (selectedIndex === 0)
                Services.Settings.setBlurEnabled(!Services.Settings.blurEnabled);
            else if (selectedIndex === 1)
                Services.Settings.setTransparentFx(!Services.Settings.transparentFx);
            else if (selectedIndex === 2)
                Services.Settings.setAnimEnabled(!Services.Settings.animEnabled);
            else if (selectedIndex === 5)
                Services.Settings.setNaturalScroll(!Services.Settings.naturalScroll);
            return;
        }
        if (root.tab === 2)
            return;
        const name = root.monitorNameAt(selectedIndex);
        if (name === "")
            return;
        root.beginMonitorChange();
        if (selectedIndex % 3 === 0)
            Services.Settings.setMonitorEnabled(name, !Services.Settings.monitorEnabled(name));
        else if (selectedIndex % 3 === 2)
            Services.Settings.cycleMonitorRes(name, 1);
    }

    function fmtTimeout(s: int): string {
        if (s <= 0)
            return "Off";
        if (s < 60)
            return s + "s";
        if (s < 3600) {
            const m = Math.floor(s / 60);
            const rest = s % 60;
            return rest === 0 ? m + "m" : m + "m " + rest + "s";
        }
        const h = Math.floor(s / 3600);
        const rest = Math.floor((s % 3600) / 60);
        return rest === 0 ? h + "h" : h + "h " + rest + "m";
    }

    property int wpCount: Math.min(Services.Settings.wallpapers.length, 4)
    property int wpListH: root.wpCount * Palette.listRowHeight + Math.max(0, root.wpCount - 1) * Palette.listSpacing
    property int monBlockH: 22 + 14 + 3 * Palette.rowHeight + 4 * Palette.listSpacing
    property int monCount: Services.Settings.monitors.length
    property int monFootH: Palette.rowHeight + Palette.listSpacing + 14

    property int mainSelH: 22 + Palette.popupSpacing + mainSelFlow.height
    function contentHeight(): int {
        if (root.tab === 0)
            return Palette.listRowHeight + Palette.listSpacing + root.wpListH;
        if (root.tab === 1)
            return 6 * Palette.rowHeight + 5 * Palette.listSpacing;
        if (root.tab === 2)
            return 4 * Palette.rowHeight + 3 * Palette.listSpacing + Palette.popupSpacing + 30;
        if (root.monCount === 0)
            return root.mainSelH + Palette.popupSpacing + 30;
        return root.mainSelH + Palette.popupSpacing + root.monCount * root.monBlockH + (root.monCount - 1) * Palette.popupSpacing + Palette.popupSpacing + root.monFootH;
    }

    PopupCard {
        Row {
            id: tabRow
            width: parent.width
            height: Palette.rowHeight
            spacing: Palette.popupSpacing
            PopupButton {
                label: "Appearance"
                columns: 4
                accent: root.tab === 0
                selected: root.tab === 0
                onClicked: root.tab = 0
            }
            PopupButton {
                label: "Hyprland"
                columns: 4
                accent: root.tab === 1
                selected: root.tab === 1
                onClicked: root.tab = 1
            }
            PopupButton {
                label: "System"
                columns: 4
                accent: root.tab === 2
                selected: root.tab === 2
                onClicked: root.tab = 2
            }
            PopupButton {
                label: "Monitors"
                columns: 4
                accent: root.tab === 3
                selected: root.tab === 3
                onClicked: root.tab = 3
            }
        }

        // Appearance tab
        Column {
            visible: root.tab === 0
            width: parent.width
            spacing: Palette.listSpacing
            Rectangle {
                width: parent.width
                height: Palette.listRowHeight
                readonly property bool current: Services.Settings.wallpaperOverride === ""
                readonly property bool selected: root.tab === 0 && root.selectedIndex === 0
                color: selected ? Palette.accent : current ? Palette.activeBg : autoHover.containsMouse ? Palette.hoverBg : "transparent"
                border.width: 1
                border.color: selected ? Palette.accent : current ? Palette.accent : Palette.dim
                Text {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: Text.AlignVCenter
                    text: (parent.current ? "✓  " : "") + "Auto (default)"
                    color: parent.selected ? Palette.onAccent : parent.current ? Palette.accent : autoHover.containsMouse ? Palette.fg : Palette.dim
                    font.family: Palette.font
                    font.pixelSize: Palette.px12
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: autoHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedIndex = 0;
                        Services.Settings.setWallpaper("");
                    }
                }
            }
            ListView {
                id: wallList
                width: parent.width
                height: root.wpListH
                clip: true
                spacing: Palette.listSpacing
                model: Services.Settings.wallpapers.slice(0, 4)
                onCountChanged: root.syncWallCursor()
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool current: modelData === Services.Settings.wallpaperOverride
                    readonly property bool selected: wallList.currentIndex === index
                    width: ListView.view.width
                    height: Palette.listRowHeight
                    color: selected ? Palette.accent : current ? Palette.activeBg : rowHover.containsMouse ? Palette.hoverBg : "transparent"
                    border.width: 1
                    border.color: selected ? Palette.accent : current ? Palette.accent : Palette.dim
                    Text {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        verticalAlignment: Text.AlignVCenter
                        text: (parent.current ? "✓  " : "") + String(modelData).split("/").pop()
                        color: parent.selected ? Palette.onAccent : parent.current ? Palette.accent : rowHover.containsMouse ? Palette.fg : Palette.dim
                        font.family: Palette.font
                        font.pixelSize: Palette.px12
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wallList.currentIndex = index;
                            root.selectedIndex = index + 1;
                            Services.Settings.setWallpaper(modelData);
                        }
                    }
                }
            }
        }

        // Hyprland tab
        Column {
            visible: root.tab === 1
            width: parent.width
            spacing: Palette.listSpacing
            SettingsRow {
                title: "Blur"
                value: Services.Settings.blurEnabled ? "On" : "Off"
                selected: root.tab === 1 && root.selectedIndex === 0
                SettingsSwitch {
                    on: Services.Settings.blurEnabled
                    onToggled: Services.Settings.setBlurEnabled(!Services.Settings.blurEnabled)
                }
            }
            SettingsRow {
                title: "Transparency"
                value: Services.Settings.transparentFx ? "On" : "Off"
                selected: root.tab === 1 && root.selectedIndex === 1
                SettingsSwitch {
                    on: Services.Settings.transparentFx
                    onToggled: Services.Settings.setTransparentFx(!Services.Settings.transparentFx)
                }
            }
            SettingsRow {
                title: "Animations"
                value: Services.Settings.animEnabled ? "On" : "Off"
                selected: root.tab === 1 && root.selectedIndex === 2
                SettingsSwitch {
                    on: Services.Settings.animEnabled
                    onToggled: Services.Settings.setAnimEnabled(!Services.Settings.animEnabled)
                }
            }
            SettingsRow {
                title: "Sensitivity"
                value: Services.Settings.sensitivity.toFixed(1)
                selected: root.tab === 1 && root.selectedIndex === 3
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    minimum: -1
                    maximum: 1
                    value: Services.Settings.sensitivity
                    onSliderMoved: value => Services.Settings.setSensitivity(value)
                }
            }
            SettingsRow {
                title: "Touchpad scroll"
                value: Services.Settings.touchScroll.toFixed(1)
                selected: root.tab === 1 && root.selectedIndex === 4
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    minimum: 0.1
                    maximum: 2
                    value: Services.Settings.touchScroll
                    onSliderMoved: value => Services.Settings.setTouchScroll(value)
                }
            }
            SettingsRow {
                title: "Natural scroll"
                value: Services.Settings.naturalScroll ? "On" : "Off"
                selected: root.tab === 1 && root.selectedIndex === 5
                SettingsSwitch {
                    on: Services.Settings.naturalScroll
                    onToggled: Services.Settings.setNaturalScroll(!Services.Settings.naturalScroll)
                }
            }
        }

        // System tab
        Column {
            visible: root.tab === 2
            width: parent.width
            spacing: Palette.listSpacing
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 0
                title: "Dim display"
                value: root.fmtTimeout(Services.Settings.dimTimeout)
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    minimum: 0
                    maximum: 10
                    value: Services.Settings.dimTimeout / 60
                    onSliderMoved: value => Services.Settings.setDimTimeout(Math.round(value * 2) * 30)
                }
            }
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 1
                title: "Lock"
                value: root.fmtTimeout(Services.Settings.lockTimeout)
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    minimum: 0
                    maximum: 60
                    value: Services.Settings.lockTimeout / 60
                    onSliderMoved: value => Services.Settings.setLockTimeout(Math.round(value) * 60)
                }
            }
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 2
                title: "Screen off"
                value: root.fmtTimeout(Services.Settings.screenOffTimeout)
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    minimum: 0
                    maximum: 60
                    value: Services.Settings.screenOffTimeout / 60
                    onSliderMoved: value => Services.Settings.setScreenOffTimeout(Math.round(value) * 60)
                }
            }
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 3
                title: "Suspend"
                value: root.fmtTimeout(Services.Settings.suspendTimeout)
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    minimum: 0
                    maximum: 120
                    value: Services.Settings.suspendTimeout / 60
                    onSliderMoved: value => Services.Settings.setSuspendTimeout(Math.round(value / 5) * 300)
                }
            }
            Text {
                width: parent.width
                height: 30
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "0 = Off. Applies to hypridle.conf and restarts hypridle."
                color: Palette.dim
                font.family: Palette.font
                font.pixelSize: Palette.px10
            }
        }

        // Monitors tab
        Column {
            visible: root.tab === 3
            width: parent.width
            spacing: Palette.popupSpacing
            Text {
                width: parent.width
                height: 22
                verticalAlignment: Text.AlignVCenter
                text: "Main display"
                color: Palette.fg
                font.family: Palette.font
                font.pixelSize: Palette.px12
                elide: Text.ElideRight
            }
            Flow {
                id: mainSelFlow
                width: parent.width
                spacing: Palette.popupSpacing
                Repeater {
                    model: ["auto"].concat(Services.Settings.monitors.map(m => String(m?.name ?? "")).filter(n => n !== ""))
                    delegate: PopupButton {
                        required property var modelData
                        label: modelData === "auto" ? "Auto" : modelData
                        columns: 2
                        accent: Services.Settings.mainMonitor === modelData
                        selected: Services.Settings.mainMonitor === modelData
                        onClicked: Services.Settings.setMainMonitor(modelData)
                    }
                }
            }
            Text {
                visible: root.monCount === 0
                width: parent.width
                height: 30
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "No monitors found. Is hyprctl reachable?"
                color: Palette.dim
                font.family: Palette.font
                font.pixelSize: Palette.px10
            }
            Repeater {
                model: Services.Settings.monitors
                delegate: Column {
                    required property var modelData
                    readonly property string monName: String(modelData.name ?? "")
                    width: parent.width
                    spacing: Palette.listSpacing
                    Text {
                        width: parent.width
                        height: 22
                        verticalAlignment: Text.AlignVCenter
                        text: Services.Settings.monitorSummary(monName)
                        color: Palette.fg
                        font.family: Palette.font
                        font.pixelSize: Palette.px12
                        elide: Text.ElideRight
                    }
                    SettingsRow {
                    selected: root.tab === 3 && root.selectedIndex === Services.Settings.monitorBase(monName) + 0
                        title: "Enabled"
                        value: Services.Settings.monitorEnabled(monName) ? "On" : "Off"
                        SettingsSwitch {
                            on: Services.Settings.monitorEnabled(monName)
                            disabled: !Services.Settings.canDisableMonitor(monName)
                            onToggled: {
                                root.beginMonitorChange();
                                Services.Settings.setMonitorEnabled(monName, !Services.Settings.monitorEnabled(monName))
                            }
                        }
                    }
                    SettingsRow {
                    selected: root.tab === 3 && root.selectedIndex === Services.Settings.monitorBase(monName) + 1
                        title: "Scale"
                        value: "x" + Services.Settings.monitorScale(monName).toFixed(2).replace(/0$/, "")
                        SliderBar {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            minimum: 0.5
                            maximum: 3
                            value: Services.Settings.monitorScale(monName)
                            onSliderMoved: value => {
                                root.beginMonitorChange();
                                Services.Settings.setMonitorScale(monName, Math.round(value * 20) / 20)
                            }
                        }
                    }
                    SettingsRow {
                    selected: root.tab === 3 && root.selectedIndex === Services.Settings.monitorBase(monName) + 2
                        title: "Resolution"
                        value: ""
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            spacing: Palette.popupSpacing
                            PopupButton {
                                label: "Previous"
                                selected: root.tab === 3 && root.selectedIndex === Services.Settings.monitorBase(monName) + 2
                                columns: 2
                                onClicked: {
                                    root.beginMonitorChange();
                                    Services.Settings.cycleMonitorRes(monName, -1)
                                }
                            }
                            PopupButton {
                                label: "Next"
                                selected: root.tab === 3 && root.selectedIndex === Services.Settings.monitorBase(monName) + 2
                                columns: 2
                                onClicked: {
                                    root.beginMonitorChange();
                                    Services.Settings.cycleMonitorRes(monName, 1)
                                }
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        height: 14
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                        text: Services.Settings.monitorRes(monName)
                        color: Palette.dim
                        font.family: Palette.font
                        font.pixelSize: Palette.px10
                    }
                }
            }
            PopupButton {
                label: "Re-detect displays"
                columns: 1
                onClicked: Services.Settings.refreshMonitors()
            }
            Text {
                width: parent.width
                height: 14
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: Services.Settings.lastApplyMsg
                color: Palette.dim
                font.family: Palette.font
                font.pixelSize: Palette.px10
            }
        }

        HintText {
            id: hint
            text: "jk move · hl adjust · ↵ activate · 1-4 tabs"
        }
    }
}
