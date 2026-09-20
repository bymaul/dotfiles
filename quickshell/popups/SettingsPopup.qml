import QtQuick
import "../components"
import "../services" as Services
BasePopup {
    id: root
    implicitWidth: Services.Theme.settingsWidth
    implicitHeight: Math.min(16 + tabRow.height + Services.Theme.popupSpacing + root.contentHeight() + Services.Theme.popupSpacing + hint.implicitHeight, (Screen.height ?? 800) - 60)
    property int tab: 0
    property int maxMonListH: 380
    function cancelOrClose(): void {
        if (root.openDropdown >= 0 || root.openMonRes !== "")
            root.closeDrop();
        else
            root.close();
    }
    Shortcut { sequence: "1"; enabled: root.visible; onActivated: root.tab = 0 }
    Shortcut { sequence: "2"; enabled: root.visible; onActivated: root.tab = 1 }
    Shortcut { sequence: "3"; enabled: root.visible; onActivated: root.tab = 2 }
    Shortcut { sequence: "4"; enabled: root.visible; onActivated: root.tab = 3 }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.adjustSelected(-1) }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.adjustSelected(1) }
    Shortcut { sequence: "Up"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Down"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Left"; enabled: root.visible; onActivated: root.adjustSelected(-1) }
    Shortcut { sequence: "Right"; enabled: root.visible; onActivated: root.adjustSelected(1) }
    Shortcut { sequence: "Tab"; enabled: root.visible && (root.tab === 2 || root.tab === 3); onActivated: root.tabStep(1) }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible && (root.tab === 2 || root.tab === 3); onActivated: root.tabStep(-1) }
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
    property int openDropdown: -1
    property string openMonRes: ""
    property int dropCursor: 0
    onTabChanged: {
        root.selectedIndex = 0;
        root.openDropdown = -1;
        root.openMonRes = "";
        root.syncWallCursor();
    }
    onWpCountChanged: root.syncWallCursor()
    onMonCountChanged: root.clampSelection()

    onVisibleChanged: {
        if (visible) {
            root.selectedIndex = 0;
            root.openDropdown = -1;
            root.openMonRes = "";
            root.syncWallCursor();
            Services.Settings.refreshWallpapers();
            Services.Settings.refreshMonitors();
        } else {
            root.preventClose = false;
            root.openDropdown = -1;
            root.openMonRes = "";
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
            return 11;
        return root.monCount * 3;
    }
    function clampSelection(): void {
        selectedIndex = Services.Theme.clamp(selectedIndex, 0, Math.max(0, root.itemCount() - 1));
    }
    function syncWallCursor(): void {
        root.clampSelection();
        if (root.tab === 0 && selectedIndex >= 1 && selectedIndex <= root.wpCount)
            wallList.currentIndex = selectedIndex - 1;
        else
            wallList.currentIndex = -1;
    }
    function stepSelection(dir: int): void {
        if (root.tab === 2 && root.openDropdown >= 0) {
            root.moveDropCursor(dir);
            return;
        }
        if (root.tab === 3 && root.openMonRes !== "") {
            root.monMoveCursor(dir);
            return;
        }
        selectedIndex += dir;
        root.syncWallCursor();
    }
    function tabStep(dir: int): void {
        if (root.openDropdown >= 0)
            root.closeDrop();
        root.stepSelection(dir);
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
            if (root.openDropdown === selectedIndex && root.openDropdown >= 0) {
                if (dir < 0)
                    root.closeDrop();
                else
                    root.commitDropCursor();
                return;
            }
            switch (selectedIndex) {
            case 0: Services.Settings.setDimTimeout(Services.Settings.dimTimeout + dir * 30); break;
            case 1: Services.Settings.setLockTimeout(Services.Settings.lockTimeout + dir * 60); break;
            case 2: Services.Settings.setScreenOffTimeout(Services.Settings.screenOffTimeout + dir * 60); break;
            case 3: Services.Settings.setSuspendTimeout(Services.Settings.suspendTimeout + dir * 300); break;
            case 4: Services.Settings.setLowBatteryPct(Services.Settings.lowBatteryPct + dir * 5); break;
            case 5: Services.Settings.setCriticalBatteryPct(Services.Settings.criticalBatteryPct + dir * 2); break;
            case 6: Services.Settings.setCriticalBatteryAction(root.cycleOpt(Services.Power.criticalOptions, Services.Settings.criticalBatteryAction, dir)); break;
            case 7: Services.Settings.setLidCloseAction(root.cycleOpt(Services.Power.lidOptions, Services.Settings.lidCloseAction, dir)); break;
            case 8: Services.Settings.setPowerButtonAction(root.cycleOpt(Services.Power.buttonOptions, Services.Settings.powerButtonAction, dir)); break;
            case 9: root.cycleActiveProfile(dir); break;
            case 10: Services.Settings.setPowerProfileOnBattery(root.cycleOpt(Services.Power.profileOptions, Services.Settings.powerProfileOnBattery, dir)); break;
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
        else if (root.openMonRes === name) {
            if (dir < 0)
                root.closeDrop();
            else
                root.commitMonCursor();
        } else
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
        if (root.tab === 2) {
            if (root.openDropdown === selectedIndex && root.openDropdown >= 0) {
                root.commitDropCursor();
                return;
            }
            if (root.isDropdownIndex(selectedIndex)) {
                if (root.dropEnabled(selectedIndex))
                    root.openDrop(selectedIndex);
                return;
            }
            return;
        }
        const name = root.monitorNameAt(selectedIndex);
        if (name === "")
            return;
        root.beginMonitorChange();
        if (selectedIndex % 3 === 0)
            Services.Settings.setMonitorEnabled(name, !Services.Settings.monitorEnabled(name));
        else if (selectedIndex % 3 === 2) {
            if (root.openMonRes === name)
                root.commitMonCursor();
            else
                root.toggleMonDrop(name);
        }
    }

    function cycleOpt(list: var, cur: string, dir: int): string {
        let i = list.indexOf(cur);
        if (i < 0)
            i = 0;
        return list[(i + dir + list.length) % list.length];
    }

    function cycleActiveProfile(dir: int): void {
        if (!Services.Power.profilesAvailable)
            return;
        const order = Services.Power.hasPerformanceProfile ? ["balanced", "powersaver", "performance"] : ["balanced", "powersaver"];
        Services.Power.setProfileByName(root.cycleOpt(order, Services.Power.profileName, dir), false);
    }

    function activeProfileOptions(): var {
        return Services.Power.hasPerformanceProfile ? ["balanced", "powersaver", "performance"] : ["balanced", "powersaver"];
    }
    function isDropdownIndex(i: int): bool {
        return root.tab === 2 && i >= 6 && i <= 10;
    }
    function dropEnabled(i: int): bool {
        if (i === 9)
            return Services.Power.profilesAvailable;
        return true;
    }
    function dropdownOptions(i: int): var {
        if (i === 6)
            return Services.Power.criticalOptions;
        if (i === 7)
            return Services.Power.lidOptions;
        if (i === 8)
            return Services.Power.buttonOptions;
        if (i === 9)
            return root.activeProfileOptions();
        if (i === 10)
            return Services.Power.profileOptions;
        return [];
    }
    function dropdownCurrent(i: int): string {
        if (i === 6)
            return Services.Settings.criticalBatteryAction;
        if (i === 7)
            return Services.Settings.lidCloseAction;
        if (i === 8)
            return Services.Settings.powerButtonAction;
        if (i === 9)
            return Services.Power.profilesAvailable ? Services.Power.profileName : "no ppd";
        if (i === 10)
            return Services.Power.profilesAvailable ? Services.Settings.powerProfileOnBattery : "no ppd";
        return "";
    }
    function applyDropValue(i: int, value: string): void {
        if (i === 6)
            Services.Settings.setCriticalBatteryAction(value);
        else if (i === 7)
            Services.Settings.setLidCloseAction(value);
        else if (i === 8)
            Services.Settings.setPowerButtonAction(value);
        else if (i === 9) {
            if (Services.Power.profilesAvailable)
                Services.Power.setProfileByName(value, false);
        } else if (i === 10)
            Services.Settings.setPowerProfileOnBattery(value);
    }
    function openDrop(i: int): void {
        if (!root.dropEnabled(i))
            return;
        const opts = root.dropdownOptions(i);
        let at = opts.indexOf(root.dropdownCurrent(i));
        if (at < 0)
            at = 0;
        root.dropCursor = at;
        root.openDropdown = i;
        root.openMonRes = "";
    }
    function closeDrop(): void {
        root.openDropdown = -1;
        root.openMonRes = "";
    }
    function toggleDrop(i: int): void {
        if (root.openDropdown === i)
            root.closeDrop();
        else
            root.openDrop(i);
    }
    function moveDropCursor(dir: int): void {
        const opts = root.dropdownOptions(root.openDropdown);
        if (opts.length === 0)
            return;
        root.dropCursor = (root.dropCursor + dir + opts.length) % opts.length;
    }
    function commitDropCursor(): void {
        const i = root.openDropdown;
        const opts = root.dropdownOptions(i);
        if (i < 0 || opts.length === 0) {
            root.closeDrop();
            return;
        }
        root.applyDropValue(i, opts[Services.Theme.clamp(root.dropCursor, 0, opts.length - 1)]);
        root.closeDrop();
    }
    function toggleMonDrop(name: string): void {
        if (root.openMonRes === name) {
            root.closeDrop();
            return;
        }
        const modes = Services.Settings.monitorModes(name);
        let at = modes.indexOf(Services.Settings.monitorRes(name));
        if (at < 0)
            at = 0;
        root.dropCursor = at;
        root.openDropdown = -1;
        root.openMonRes = name;
    }
    function monMoveCursor(dir: int): void {
        const modes = Services.Settings.monitorModes(root.openMonRes);
        if (modes.length === 0)
            return;
        root.dropCursor = (root.dropCursor + dir + modes.length) % modes.length;
    }
    function commitMonRes(name: string, res: string): void {
        root.beginMonitorChange();
        Services.Settings.setMonitorRes(name, res);
        root.closeDrop();
    }
    function commitMonCursor(): void {
        const name = root.openMonRes;
        const modes = Services.Settings.monitorModes(name);
        if (name === "" || modes.length === 0) {
            root.closeDrop();
            return;
        }
        root.commitMonRes(name, modes[Services.Theme.clamp(root.dropCursor, 0, modes.length - 1)]);
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
    property int wpListH: root.wpCount * Services.Theme.listRowHeight + Math.max(0, root.wpCount - 1) * Services.Theme.listSpacing
    property int monBlockH: 22 + 3 * Services.Theme.rowHeight + 3 * Services.Theme.listSpacing
    property int monCount: Services.Settings.monitors.length
    property int monFootH: Services.Theme.rowHeight + Services.Theme.listSpacing + 14
    property int monFullH: root.monCount * root.monBlockH + Math.max(0, root.monCount - 1) * Services.Theme.popupSpacing
    property int monListH: Math.min(root.monFullH, root.maxMonListH)

    property int mainSelH: 22 + Services.Theme.popupSpacing + mainSelFlow.height
    function contentHeight(): int {
        if (root.tab === 0)
            return Services.Theme.listRowHeight + Services.Theme.listSpacing + root.wpListH;
        if (root.tab === 1)
            return 6 * Services.Theme.rowHeight + 5 * Services.Theme.listSpacing;
        if (root.tab === 2)
            return 11 * Services.Theme.rowHeight + 10 * Services.Theme.listSpacing + Services.Theme.popupSpacing + 30;
        if (root.monCount === 0)
            return root.mainSelH + Services.Theme.popupSpacing + 30;
        return root.mainSelH + Services.Theme.popupSpacing + root.monListH + Services.Theme.popupSpacing + root.monFootH;
    }
    function ensureMonVisible(): void {
        try {
            if (root.tab !== 3)
                return;
            if (typeof monList === "undefined" || !monList || monList.count === 0)
                return;
            const mi = Math.floor(root.selectedIndex / 3);
            if (mi >= 0 && mi < monList.count)
                monList.positionViewAtIndex(mi, ListView.Contain);
        } catch (_) {}
    }
    onSelectedIndexChanged: root.ensureMonVisible()

    PopupCard {
        Row {
            id: tabRow
            width: parent.width
            height: Services.Theme.rowHeight
            spacing: Services.Theme.popupSpacing
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

        Column {
            visible: root.tab === 0
            width: parent.width
            spacing: Services.Theme.listSpacing
            Rectangle {
                width: parent.width
                height: Services.Theme.listRowHeight
                readonly property bool current: Services.Settings.wallpaperOverride === ""
                readonly property bool selected: root.tab === 0 && root.selectedIndex === 0
                color: selected ? Services.Theme.activeBg : current ? Services.Theme.activeBg : autoHover.containsMouse ? Services.Theme.hoverBg : "transparent"
                border.width: (!selected && current) ? 1 : 0
                border.color: Services.Theme.accent
                Text {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: Text.AlignVCenter
                    text: (parent.current ? "✓  " : "") + "Auto (default)"
                    color: parent.selected ? Services.Theme.fg : parent.current ? Services.Theme.accent : autoHover.containsMouse ? Services.Theme.fg : Services.Theme.dim
                    font.family: Services.Theme.font
                    font.pixelSize: Services.Theme.px12
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: autoHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: {
                        if (containsMouse)
                            root.selectedIndex = 0;
                    }
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
                spacing: Services.Theme.listSpacing
                model: Services.Settings.wallpapers.slice(0, 4)
                onCountChanged: root.syncWallCursor()
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool current: modelData === Services.Settings.wallpaperOverride
                    readonly property bool selected: wallList.currentIndex === index
                    width: ListView.view.width
                    height: Services.Theme.listRowHeight
                    color: selected ? Services.Theme.activeBg : current ? Services.Theme.activeBg : rowHover.containsMouse ? Services.Theme.hoverBg : "transparent"
                    border.width: (!selected && current) ? 1 : 0
                    border.color: Services.Theme.accent
                    Text {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        verticalAlignment: Text.AlignVCenter
                        text: (parent.current ? "✓  " : "") + String(modelData).split("/").pop()
                        color: parent.selected ? Services.Theme.fg : parent.current ? Services.Theme.accent : rowHover.containsMouse ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse) {
                                wallList.currentIndex = index;
                                root.selectedIndex = index + 1;
                            }
                        }
                        onClicked: {
                            wallList.currentIndex = index;
                            root.selectedIndex = index + 1;
                            Services.Settings.setWallpaper(modelData);
                        }
                    }
                }
            }
        }

        Column {
            visible: root.tab === 1
            width: parent.width
            spacing: Services.Theme.listSpacing
            SettingsRow {
                title: "Blur"
                value: Services.Settings.blurEnabled ? "On" : "Off"
                selected: root.tab === 1 && root.selectedIndex === 0
                onHovered: root.selectedIndex = 0
                SettingsSwitch {
                    on: Services.Settings.blurEnabled
                    onToggled: Services.Settings.setBlurEnabled(!Services.Settings.blurEnabled)
                }
            }
            SettingsRow {
                title: "Transparency"
                value: Services.Settings.transparentFx ? "On" : "Off"
                selected: root.tab === 1 && root.selectedIndex === 1
                onHovered: root.selectedIndex = 1
                SettingsSwitch {
                    on: Services.Settings.transparentFx
                    onToggled: Services.Settings.setTransparentFx(!Services.Settings.transparentFx)
                }
            }
            SettingsRow {
                title: "Animations"
                value: Services.Settings.animEnabled ? "On" : "Off"
                selected: root.tab === 1 && root.selectedIndex === 2
                onHovered: root.selectedIndex = 2
                SettingsSwitch {
                    on: Services.Settings.animEnabled
                    onToggled: Services.Settings.setAnimEnabled(!Services.Settings.animEnabled)
                }
            }
            SettingsRow {
                title: "Sensitivity"
                value: Services.Settings.sensitivity.toFixed(1)
                selected: root.tab === 1 && root.selectedIndex === 3
                onHovered: root.selectedIndex = 3
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
                onHovered: root.selectedIndex = 4
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
                onHovered: root.selectedIndex = 5
                SettingsSwitch {
                    on: Services.Settings.naturalScroll
                    onToggled: Services.Settings.setNaturalScroll(!Services.Settings.naturalScroll)
                }
            }
        }

        Column {
            visible: root.tab === 2
            width: parent.width
            spacing: Services.Theme.listSpacing
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 0
                onHovered: root.selectedIndex = 0
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
                onHovered: root.selectedIndex = 1
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
                onHovered: root.selectedIndex = 2
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
                onHovered: root.selectedIndex = 3
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
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 4
                onHovered: root.selectedIndex = 4
                title: "Low battery"
                value: Services.Settings.lowBatteryPct + "%"
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    minimum: 5
                    maximum: 50
                    value: Services.Settings.lowBatteryPct
                    onSliderMoved: value => Services.Settings.setLowBatteryPct(Math.round(value / 5) * 5)
                }
            }
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 5
                onHovered: root.selectedIndex = 5
                title: "Critical battery"
                titleWidth: 124
                value: Services.Settings.criticalBatteryPct + "%"
                SliderBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    minimum: 3
                    maximum: 30
                    value: Services.Settings.criticalBatteryPct
                    onSliderMoved: value => Services.Settings.setCriticalBatteryPct(Math.round(value / 2) * 2)
                }
            }
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 6
                onHovered: root.selectedIndex = 6
                title: "Critical action"
                value: ""
                z: root.openDropdown === 6 ? 100 : 0
                Dropdown {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    options: Services.Power.criticalOptions
                    current: Services.Settings.criticalBatteryAction
                    open: root.openDropdown === 6
                    selected: root.tab === 2 && root.selectedIndex === 6
                    cursor: root.dropCursor
                    onHeaderClicked: {
                        root.selectedIndex = 6;
                        root.toggleDrop(6);
                    }
                    onOptionHovered: index => root.dropCursor = index
                    onOptionClicked: value => {
                        root.selectedIndex = 6;
                        root.applyDropValue(6, value);
                        root.closeDrop();
                    }
                }
            }
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 7
                onHovered: root.selectedIndex = 7
                title: "Lid close"
                value: ""
                z: root.openDropdown === 7 ? 100 : 0
                Dropdown {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    options: Services.Power.lidOptions
                    current: Services.Settings.lidCloseAction
                    open: root.openDropdown === 7
                    selected: root.tab === 2 && root.selectedIndex === 7
                    cursor: root.dropCursor
                    onHeaderClicked: {
                        root.selectedIndex = 7;
                        root.toggleDrop(7);
                    }
                    onOptionHovered: index => root.dropCursor = index
                    onOptionClicked: value => {
                        root.selectedIndex = 7;
                        root.applyDropValue(7, value);
                        root.closeDrop();
                    }
                }
            }
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 8
                onHovered: root.selectedIndex = 8
                title: "Power button"
                value: ""
                z: root.openDropdown === 8 ? 100 : 0
                Dropdown {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    options: Services.Power.buttonOptions
                    current: Services.Settings.powerButtonAction
                    open: root.openDropdown === 8
                    selected: root.tab === 2 && root.selectedIndex === 8
                    cursor: root.dropCursor
                    openUp: true
                    onHeaderClicked: {
                        root.selectedIndex = 8;
                        root.toggleDrop(8);
                    }
                    onOptionHovered: index => root.dropCursor = index
                    onOptionClicked: value => {
                        root.selectedIndex = 8;
                        root.applyDropValue(8, value);
                        root.closeDrop();
                    }
                }
            }
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 9
                onHovered: root.selectedIndex = 9
                title: "Active profile"
                value: ""
                z: root.openDropdown === 9 ? 100 : 0
                Dropdown {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    options: root.activeProfileOptions()
                    current: Services.Power.profilesAvailable ? Services.Power.profileName : "no ppd"
                    enabled: Services.Power.profilesAvailable
                    open: root.openDropdown === 9
                    selected: root.tab === 2 && root.selectedIndex === 9
                    cursor: root.dropCursor
                    openUp: true
                    onHeaderClicked: {
                        root.selectedIndex = 9;
                        root.toggleDrop(9);
                    }
                    onOptionHovered: index => root.dropCursor = index
                    onOptionClicked: value => {
                        root.selectedIndex = 9;
                        root.applyDropValue(9, value);
                        root.closeDrop();
                    }
                }
            }
            SettingsRow {
                selected: root.tab === 2 && root.selectedIndex === 10
                onHovered: root.selectedIndex = 10
                title: "On battery"
                value: ""
                z: root.openDropdown === 10 ? 100 : 0
                Dropdown {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    options: Services.Power.profileOptions
                    current: Services.Power.profilesAvailable ? Services.Settings.powerProfileOnBattery : "no ppd"
                    open: root.openDropdown === 10
                    selected: root.tab === 2 && root.selectedIndex === 10
                    cursor: root.dropCursor
                    openUp: true
                    onHeaderClicked: {
                        root.selectedIndex = 10;
                        root.toggleDrop(10);
                    }
                    onOptionHovered: index => root.dropCursor = index
                    onOptionClicked: value => {
                        root.selectedIndex = 10;
                        root.applyDropValue(10, value);
                        root.closeDrop();
                    }
                }
            }
            Text {
                width: parent.width
                height: 30
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "Idle rows write hypridle.conf. Lid close needs logind: bin/qs-power-logind. Power key applies instantly."
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px10
            }
        }

        Column {
            visible: root.tab === 3
            width: parent.width
            spacing: Services.Theme.popupSpacing
            Text {
                width: parent.width
                height: 22
                verticalAlignment: Text.AlignVCenter
                text: "Main display"
                color: Services.Theme.fg
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
                elide: Text.ElideRight
            }
            Flow {
                id: mainSelFlow
                width: parent.width
                spacing: Services.Theme.popupSpacing
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
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px10
            }
            ListView {
                id: monList
                visible: root.monCount > 0
                width: parent.width
                height: root.monListH
                clip: true
                spacing: Services.Theme.popupSpacing
                model: Services.Settings.monitors
                delegate: Column {
                    required property var modelData
                    required property int index
                    readonly property string monName: String(modelData.name ?? "")
                    width: ListView.view.width
                    height: root.monBlockH
                    spacing: Services.Theme.listSpacing
                    Text {
                        width: parent.width
                        height: 22
                        verticalAlignment: Text.AlignVCenter
                        text: Services.Settings.monitorSummary(monName)
                        color: Services.Theme.fg
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                        elide: Text.ElideRight
                    }
                    SettingsRow {
                    selected: root.tab === 3 && root.selectedIndex === Services.Settings.monitorBase(monName) + 0
                    onHovered: root.selectedIndex = Services.Settings.monitorBase(monName) + 0
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
                    onHovered: root.selectedIndex = Services.Settings.monitorBase(monName) + 1
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
                    onHovered: root.selectedIndex = Services.Settings.monitorBase(monName) + 2
                        title: "Resolution"
                        value: ""
                        z: root.openMonRes === monName ? 100 : 0
                        Dropdown {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            options: Services.Settings.monitorModes(monName)
                            current: Services.Settings.monitorRes(monName)
                            open: root.openMonRes === monName
                            selected: root.tab === 3 && root.selectedIndex === Services.Settings.monitorBase(monName) + 2
                            cursor: root.dropCursor
                            openUp: index === root.monCount - 1
                            onHeaderClicked: {
                                root.selectedIndex = Services.Settings.monitorBase(monName) + 2;
                                root.toggleMonDrop(monName);
                            }
                            onOptionHovered: optIdx => root.dropCursor = optIdx
                            onOptionClicked: value => {
                                root.selectedIndex = Services.Settings.monitorBase(monName) + 2;
                                root.commitMonRes(monName, value);
                            }
                        }
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
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px10
            }
        }

        HintText {
            id: hint
            text: "1-4 tabs · jk move · hl adjust · ↵ open/pick"
        }
    }
}
