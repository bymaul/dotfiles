import QtQuick
import "../components"
import "../services" as Services
BasePopup {
    id: root
    implicitWidth: Services.Theme.settingsWidth
    implicitHeight: Math.min(16 + tabRow.height + Services.Theme.popupSpacing + root.contentHeight() + Services.Theme.popupSpacing + hint.implicitHeight, (Screen.height ?? 800) - 60)
    property int tab: 0
    function cancelOrClose(): void {
        if (root.openMenu !== null)
            root.closeDrop();
        else
            root.close();
    }
    Shortcut { sequence: "1"; enabled: root.visible; onActivated: root.tab = 0 }
    Shortcut { sequence: "2"; enabled: root.visible; onActivated: root.tab = 1 }
    Shortcut { sequence: "3"; enabled: root.visible; onActivated: root.tab = 2 }
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "h"; enabled: root.visible; onActivated: root.adjustSelected(-1) }
    Shortcut { sequence: "l"; enabled: root.visible; onActivated: root.adjustSelected(1) }
    Shortcut { sequence: "Up"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Down"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Left"; enabled: root.visible; onActivated: root.adjustSelected(-1) }
    Shortcut { sequence: "Right"; enabled: root.visible; onActivated: root.adjustSelected(1) }
    Shortcut { sequence: "Tab"; enabled: root.visible; onActivated: root.tabStep(1) }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible; onActivated: root.tabStep(-1) }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.activateSelected() }

    Connections {
        target: Services.Settings
        function onLastApplyMsgChanged(): void {
            if (!root.preventClose)
                return;
            root.kickBusy();
        }
    }

    property int selectedIndex: 0
    // Single source of truth for open menus. null when closed, otherwise
    // {kind: "sys", index} | {kind: "main"} | {kind: "res"|"pos", name}.
    // The open* properties below are read-only views; write via
    // openDrop/toggleMonDrop/toggleMonPosDrop/toggleMainDrop/closeDrop only.
    property var openMenu: null
    readonly property int openDropdown: root.openMenu && root.openMenu.kind === "sys" ? root.openMenu.index : -1
    readonly property string openMonRes: root.openMenu && root.openMenu.kind === "res" ? root.openMenu.name : ""
    readonly property string openMonPos: root.openMenu && root.openMenu.kind === "pos" ? root.openMenu.name : ""
    readonly property bool openMainDrop: root.openMenu !== null && root.openMenu.kind === "main"
    property int dropCursor: 0
    onTabChanged: {
        root.selectedIndex = 0;
        root.closeDrop();
        root.syncWallCursor();
        if (root.visible && root.tab === 2)
            Services.Settings.refreshMonitors(false);
    }
    onWpCountChanged: root.syncWallCursor()
    onMonCountChanged: {
        if (root.openMonRes !== "" && Services.Settings.monitorLive(root.openMonRes) === null)
            root.closeDrop();
        if (root.openMonPos !== "" && Services.Settings.monitorLive(root.openMonPos) === null)
            root.closeDrop();
        root.clampSelection();
    }
    onEnabledCountChanged: {
        if (root.enabledCount < 2 && root.openMainDrop)
            root.closeDrop();
        root.clampSelection();
    }

    onVisibleChanged: {
        if (visible) {
            root.selectedIndex = 0;
            root.closeDrop();
            root.syncWallCursor();
            Services.Settings.refreshWallpapers(false);
            if (root.tab === 2)
                Services.Settings.refreshMonitors(false);
        } else {
            root.calmBusy();
            root.closeDrop();
        }
    }

    function beginMonitorChange(): void {
        root.kickBusy();
    }
    function toggleMonitorEnabled(name: string): void {
        if (name === "")
            return;
        if (Services.Settings.monitorEnabled(name) && !Services.Settings.canDisableMonitor(name)) {
            Services.Settings.setMonitorEnabled(name, false);
            return;
        }
        root.beginMonitorChange();
        Services.Settings.setMonitorEnabled(name, !Services.Settings.monitorEnabled(name));
    }
    function itemCount(): int {
        if (root.tab === 0)
            return root.wpRows + root.inputRows;
        if (root.tab === 1)
            return 10;
        return root.monFirst + root.monCount * root.monRows + 1;
    }
    function monLastIndex(): int {
        return root.monFirst + root.monCount * root.monRows;
    }
    function anyDropOpen(): bool {
        return root.openMenu !== null;
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
        if (root.tab === 1 && root.openDropdown >= 0) {
            root.moveCursor(root.dropdownOptions(root.openDropdown), dir);
            return;
        }
        if (root.tab === 2 && root.openMainDrop) {
            root.moveCursor(root.mainOptions(), dir);
            return;
        }
        if (root.tab === 2 && root.openMonRes !== "") {
            root.moveCursor(Services.Settings.monitorModes(root.openMonRes), dir);
            return;
        }
        if (root.tab === 2 && root.openMonPos !== "") {
            root.moveCursor(Services.Settings.monitorPosOptions(), dir);
            return;
        }
        selectedIndex += dir;
        root.clampSelection();
        root.syncWallCursor();
    }
    function tabStep(dir: int): void {
        root.closeDrop();
        const n = 3;
        root.tab = (root.tab + dir + n) % n;
    }
    function monitorNameAt(i: int): string {
        if (i < root.monFirst || i >= root.monFirst + root.monCount * root.monRows)
            return "";
        const m = Services.Settings.monitors[Math.floor((i - root.monFirst) / root.monRows)] ?? null;
        return m && typeof m.name === "string" ? m.name : "";
    }
    function adjustSelected(dir: int): void {
        if (root.tab === 0) {
            if (selectedIndex < root.wpRows) {
                root.stepSelection(dir);
                return;
            }
            switch (selectedIndex - root.wpRows) {
            case 0: Services.Settings.setSensitivity(Services.Settings.sensitivity + dir * 0.1); break;
            case 1: Services.Settings.setTouchScroll(Services.Settings.touchScroll + dir * 0.1); break;
            case 2: Services.Settings.setNaturalScroll(!Services.Settings.naturalScroll); break;
            }
            return;
        }
        if (root.tab === 1) {
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
            case 8: root.cycleActiveProfile(dir); break;
            case 9: Services.Settings.setPowerProfileOnBattery(root.cycleOpt(Services.Power.profileOptions, Services.Settings.powerProfileOnBattery, dir)); break;
            }
            return;
        }
        if (root.tab === 2 && root.selectedIndex === 0) {
            if (root.openMainDrop) {
                if (dir < 0)
                    root.closeDrop();
                else
                    root.commitMainCursor();
                return;
            }
            root.cycleMainMonitor(dir);
            return;
        }
        if (root.tab === 2 && root.selectedIndex === root.monLastIndex())
            return;
        const name = root.monitorNameAt(selectedIndex);
        if (name === "")
            return;
        const kind = (selectedIndex - root.monFirst) % root.monRows;
        if (kind === 0) {
            root.toggleMonitorEnabled(name);
        } else if (kind === 1) {
            root.beginMonitorChange();
            Services.Settings.setMonitorScale(name, Services.Settings.monitorScale(name) + dir * 0.05);
        } else if (kind === 2) {
            if (root.openMonRes === name) {
                if (dir < 0)
                    root.closeDrop();
                else
                    root.commitMonCursor();
            } else {
                root.beginMonitorChange();
                Services.Settings.cycleMonitorRes(name, dir);
            }
        } else if (kind === 3) {
            if (root.openMonPos === name) {
                if (dir < 0)
                    root.closeDrop();
                else
                    root.commitMonPosCursor();
            } else {
                root.beginMonitorChange();
                Services.Settings.cycleMonitorPos(name, dir);
            }
        }
        return;
    }
    function activateSelected(): void {
        if (root.tab === 0) {
            if (selectedIndex === 0)
                Services.Settings.setWallpaper("");
            else if (selectedIndex <= root.wpCount)
                Services.Settings.setWallpaper(Services.Settings.wallpapers[selectedIndex - 1] ?? "");
            else if (selectedIndex === root.wpRows + 2)
                Services.Settings.setNaturalScroll(!Services.Settings.naturalScroll);
            return;
        }
        if (root.tab === 1) {
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
        if (root.tab === 2 && root.selectedIndex === 0) {
            if (root.openMainDrop)
                root.commitMainCursor();
            else
                root.toggleMainDrop();
            return;
        }
        if (root.tab === 2 && root.selectedIndex === root.monLastIndex()) {
            Services.Settings.refreshMonitors(true);
            return;
        }
        const name = root.monitorNameAt(selectedIndex);
        if (name === "")
            return;
        if ((selectedIndex - root.monFirst) % root.monRows === 0)
            root.toggleMonitorEnabled(name);
        else if ((selectedIndex - root.monFirst) % root.monRows === 2) {
            if (root.openMonRes === name)
                root.commitMonCursor();
            else
                root.toggleMonDrop(name);
        } else if ((selectedIndex - root.monFirst) % root.monRows === 3) {
            if (root.openMonPos === name)
                root.commitMonPosCursor();
            else
                root.toggleMonPosDrop(name);
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
        return root.tab === 1 && i >= 6 && i <= 9;
    }
    function dropEnabled(i: int): bool {
        if (i === 8)
            return Services.Power.profilesAvailable;
        return true;
    }
    function dropdownOptions(i: int): var {
        if (i === 6)
            return Services.Power.criticalOptions;
        if (i === 7)
            return Services.Power.lidOptions;
        if (i === 8)
            return root.activeProfileOptions();
        if (i === 9)
            return Services.Power.profileOptions;
        return [];
    }
    function dropdownCurrent(i: int): string {
        if (i === 6)
            return Services.Settings.criticalBatteryAction;
        if (i === 7)
            return Services.Settings.lidCloseAction;
        if (i === 8)
            return Services.Power.profilesAvailable ? Services.Power.profileName : "no ppd";
        if (i === 9)
            return Services.Power.profilesAvailable ? Services.Settings.powerProfileOnBattery : "no ppd";
        return "";
    }
    function applyDropValue(i: int, value: string): void {
        if (i === 6)
            Services.Settings.setCriticalBatteryAction(value);
        else if (i === 7)
            Services.Settings.setLidCloseAction(value);
        else if (i === 8) {
            if (Services.Power.profilesAvailable)
                Services.Power.setProfileByName(value, false);
        } else if (i === 9)
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
        root.openMenu = {kind: "sys", index: i};
    }
    function closeDrop(): void {
        root.openMenu = null;
    }
    function toggleDrop(i: int): void {
        if (root.openDropdown === i)
            root.closeDrop();
        else
            root.openDrop(i);
    }
    function moveCursor(opts: var, dir: int): void {
        if (!opts || opts.length === 0)
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
        root.openMenu = {kind: "res", name: name};
    }
    function mainOptions(): var {
        return Services.Settings.mainMonitorOptions();
    }
    function toggleMonPosDrop(name: string): void {
        if (root.openMonPos === name) {
            root.closeDrop();
            return;
        }
        const opts = Services.Settings.monitorPosOptions();
        let at = opts.indexOf(Services.Settings.monitorPos(name));
        if (at < 0)
            at = 0;
        root.dropCursor = at;
        root.openMenu = {kind: "pos", name: name};
    }
    function commitMonPos(name: string, pos: string): void {
        root.beginMonitorChange();
        Services.Settings.setMonitorPos(name, pos);
        root.closeDrop();
    }
    function commitMonPosCursor(): void {
        const name = root.openMonPos;
        const opts = Services.Settings.monitorPosOptions();
        if (name === "" || opts.length === 0) {
            root.closeDrop();
            return;
        }
        root.commitMonPos(name, opts[Services.Theme.clamp(root.dropCursor, 0, opts.length - 1)]);
    }
    function toggleMainDrop(): void {
        if (root.enabledCount < 2)
            return;
        if (root.openMainDrop) {
            root.closeDrop();
            return;
        }
        const opts = root.mainOptions();
        let at = opts.indexOf(Services.Settings.mainMonitor);
        if (at < 0)
            at = 0;
        root.dropCursor = at;
        root.openMenu = {kind: "main"};
    }
    function cycleMainMonitor(dir: int): void {
        if (root.enabledCount < 2)
            return;
        const opts = root.mainOptions();
        if (opts.length === 0)
            return;
        Services.Settings.setMainMonitor(root.cycleOpt(opts, Services.Settings.mainMonitor, dir));
    }
    function commitMainCursor(): void {
        const opts = root.mainOptions();
        if (!root.openMainDrop || opts.length === 0) {
            root.closeDrop();
            return;
        }
        Services.Settings.setMainMonitor(opts[Services.Theme.clamp(root.dropCursor, 0, opts.length - 1)]);
        root.closeDrop();
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
    property int wpRows: root.wpCount + 1
    property int inputRows: 3
    property int sectionH: 18
    property int enabledCount: Services.Settings.enabledMonitors().length
    property int monFirst: 1
    property int monRows: 4
    property int monCardPad: 8
    property int monHeaderH: 22
    property int monBlockH: root.monHeaderH + root.monRows * Services.Theme.rowHeight + root.monRows * Services.Theme.listSpacing + 2 * root.monCardPad
    property int monCount: Services.Settings.monitors.length
    property int monFootH: Services.Theme.rowHeight + Services.Theme.popupSpacing + 14
    property int monFullH: root.monCount * root.monBlockH + Math.max(0, root.monCount - 1) * Services.Theme.popupSpacing

    property int mainSelH: Services.Theme.rowHeight
    property int wallColH: Services.Theme.listRowHeight + Services.Theme.listSpacing + root.wpListH
    property int inputColH: 3 * Services.Theme.rowHeight + 2 * Services.Theme.listSpacing
    property int sysIdleH: 4 * Services.Theme.rowHeight + 3 * Services.Theme.listSpacing
    property int sysBattH: 4 * Services.Theme.rowHeight + 3 * Services.Theme.listSpacing
    property int sysProfH: 2 * Services.Theme.rowHeight + Services.Theme.listSpacing
    function contentHeight(): int {
        if (root.tab === 0)
            return root.wallColH + Services.Theme.popupSpacing + root.sectionH + Services.Theme.popupSpacing + root.inputColH;
        if (root.tab === 1)
            return root.sysIdleH + root.sysBattH + root.sysProfH + 3 * root.sectionH + 30 + 6 * Services.Theme.popupSpacing;
        if (root.monCount === 0)
            return root.mainSelH + Services.Theme.popupSpacing + 30 + Services.Theme.popupSpacing + root.monFootH;
        return root.mainSelH + Services.Theme.popupSpacing + root.monFullH + Services.Theme.popupSpacing + root.monFootH;
    }
    PopupCard {
        Row {
            id: tabRow
            width: parent.width
            height: Services.Theme.rowHeight
            spacing: Services.Theme.popupSpacing
            PopupButton {
                label: "General"
                columns: 3
                accent: root.tab === 0
                selected: root.tab === 0
                onClicked: root.tab = 0
            }
            PopupButton {
                label: "System"
                columns: 3
                accent: root.tab === 1
                selected: root.tab === 1
                onClicked: root.tab = 1
            }
            PopupButton {
                label: "Displays"
                columns: 3
                accent: root.tab === 2
                selected: root.tab === 2
                onClicked: root.tab = 2
            }
        }

        Column {
            visible: root.tab === 0
            width: parent.width
            spacing: Services.Theme.popupSpacing
            Column {
                width: parent.width
                spacing: Services.Theme.listSpacing
                Rectangle {
                    width: parent.width
                    height: Services.Theme.listRowHeight
                    readonly property bool current: Services.Settings.wallpaperOverride === ""
                    readonly property bool selected: root.tab === 0 && root.selectedIndex === 0
                    color: selected ? Services.Theme.activeBg : current ? Services.Theme.activeBg : autoHover.containsMouse ? Services.Theme.hoverBg : Services.Theme.transparent
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
                        color: selected ? Services.Theme.activeBg : current ? Services.Theme.activeBg : rowHover.containsMouse ? Services.Theme.hoverBg : Services.Theme.transparent
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
            Text {
                width: parent.width
                height: root.sectionH
                verticalAlignment: Text.AlignVCenter
                text: "Mouse & touchpad"
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px11
            }
            Column {
                width: parent.width
                spacing: Services.Theme.listSpacing
                SettingsRow {
                    title: "Sensitivity"
                    value: Services.Settings.sensitivity.toFixed(1)
                    selected: root.tab === 0 && root.selectedIndex === root.wpRows + 0
                    onHovered: root.selectedIndex = root.wpRows + 0
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
                    selected: root.tab === 0 && root.selectedIndex === root.wpRows + 1
                    onHovered: root.selectedIndex = root.wpRows + 1
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
                    selected: root.tab === 0 && root.selectedIndex === root.wpRows + 2
                    onHovered: root.selectedIndex = root.wpRows + 2
                    SettingsSwitch {
                        on: Services.Settings.naturalScroll
                        onToggled: Services.Settings.setNaturalScroll(!Services.Settings.naturalScroll)
                    }
                }
            }
        }

        Column {
            visible: root.tab === 1
            width: parent.width
            spacing: Services.Theme.popupSpacing
            Text {
                width: parent.width
                height: root.sectionH
                verticalAlignment: Text.AlignVCenter
                text: "Idle"
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px11
            }
            Column {
                width: parent.width
                spacing: Services.Theme.listSpacing
            SettingsRow {
                selected: root.tab === 1 && root.selectedIndex === 0
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 0;
                }
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
                selected: root.tab === 1 && root.selectedIndex === 1
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 1;
                }
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
                selected: root.tab === 1 && root.selectedIndex === 2
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 2;
                }
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
                selected: root.tab === 1 && root.selectedIndex === 3
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 3;
                }
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
            }
            Text {
                width: parent.width
                height: root.sectionH
                verticalAlignment: Text.AlignVCenter
                text: "Battery"
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px11
            }
            Column {
                width: parent.width
                spacing: Services.Theme.listSpacing
                z: root.openDropdown === 6 || root.openDropdown === 7 ? 50 : 0
            SettingsRow {
                selected: root.tab === 1 && root.selectedIndex === 4
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 4;
                }
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
                selected: root.tab === 1 && root.selectedIndex === 5
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 5;
                }
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
            DropdownRow {
                selected: root.tab === 1 && root.selectedIndex === 6
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 6;
                }
                title: "Critical action"
                z: root.openDropdown === 6 ? 100 : 0
                options: Services.Power.criticalOptions
                current: Services.Settings.criticalBatteryAction
                dropOpen: root.openDropdown === 6
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
            DropdownRow {
                selected: root.tab === 1 && root.selectedIndex === 7
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 7;
                }
                title: "Lid close"
                z: root.openDropdown === 7 ? 100 : 0
                options: Services.Power.lidOptions
                current: Services.Settings.lidCloseAction
                dropOpen: root.openDropdown === 7
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
            Text {
                width: parent.width
                height: root.sectionH
                verticalAlignment: Text.AlignVCenter
                text: "Profiles"
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px11
            }
            Column {
                width: parent.width
                spacing: Services.Theme.listSpacing
                z: root.openDropdown === 8 || root.openDropdown === 9 ? 50 : 0
            DropdownRow {
                selected: root.tab === 1 && root.selectedIndex === 8
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 8;
                }
                title: "Active profile"
                z: root.openDropdown === 8 ? 100 : 0
                options: root.activeProfileOptions()
                current: Services.Power.profilesAvailable ? Services.Power.profileName : "no ppd"
                dropEnabled: Services.Power.profilesAvailable
                dropOpen: root.openDropdown === 8
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
            DropdownRow {
                selected: root.tab === 1 && root.selectedIndex === 9
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 9;
                }
                title: "On battery"
                z: root.openDropdown === 9 ? 100 : 0
                options: Services.Power.profileOptions
                current: Services.Power.profilesAvailable ? Services.Settings.powerProfileOnBattery : "no ppd"
                dropOpen: root.openDropdown === 9
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
            Text {
                width: parent.width
                height: 30
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "Idle rows write hypridle.conf. Lid close needs logind: bin/qs-power-logind. Power key suspends."
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px10
            }
        }

        Column {
            visible: root.tab === 2
            width: parent.width
            spacing: Services.Theme.popupSpacing
            DropdownRow {
                title: "Main display"
                selected: root.tab === 2 && root.selectedIndex === 0
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = 0;
                }
                z: root.openMainDrop ? 100 : 0
                options: root.mainOptions()
                current: Services.Settings.mainMonitor
                dropEnabled: root.enabledCount > 1
                dropOpen: root.openMainDrop
                cursor: root.dropCursor
                onHeaderClicked: {
                    root.selectedIndex = 0;
                    root.toggleMainDrop();
                }
                onOptionHovered: index => root.dropCursor = index
                onOptionClicked: value => {
                    root.selectedIndex = 0;
                    Services.Settings.setMainMonitor(value);
                    root.closeDrop();
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
            Column {
                id: monColumn
                visible: root.monCount > 0
                width: parent.width
                spacing: Services.Theme.popupSpacing
                z: root.openMonRes !== "" || root.openMonPos !== "" ? 50 : 0
                Repeater {
                    model: Services.Settings.monitors
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property string monName: String(modelData.name ?? "")
                        readonly property bool monOn: Services.Settings.monitorEnabled(monName)
                        width: parent.width
                        height: root.monBlockH
                        color: Services.Theme.transparent
                        border.width: 1
                        border.color: Services.Theme.border
                        z: root.openMonRes === monName || root.openMonPos === monName ? 100 : 0
                        Column {
                            anchors.fill: parent
                            anchors.margins: root.monCardPad
                            spacing: Services.Theme.listSpacing
                    Text {
                        width: parent.width
                        height: root.monHeaderH
                        verticalAlignment: Text.AlignVCenter
                        text: Services.Settings.monitorSummary(monName)
                        color: monOn ? Services.Theme.fg : Services.Theme.dim
                        font.family: Services.Theme.font
                        font.pixelSize: Services.Theme.px12
                        elide: Text.ElideRight
                    }
                    SettingsRow {
                    selected: root.tab === 2 && root.selectedIndex === root.monFirst + index * root.monRows + 0
                    onHovered: {
                        if (!root.anyDropOpen())
                            root.selectedIndex = root.monFirst + index * root.monRows + 0;
                    }
                        title: "Enabled"
                        value: monOn ? "On" : "Off"
                        SettingsSwitch {
                            on: monOn
                            disabled: !Services.Settings.canDisableMonitor(monName)
                            onToggled: {
                                root.beginMonitorChange();
                                Services.Settings.setMonitorEnabled(monName, !Services.Settings.monitorEnabled(monName))
                            }
                        }
                    }
                    SettingsRow {
                    opacity: monOn ? 1 : 0.45
                    selected: root.tab === 2 && root.selectedIndex === root.monFirst + index * root.monRows + 1
                    onHovered: {
                        if (!root.anyDropOpen())
                            root.selectedIndex = root.monFirst + index * root.monRows + 1;
                    }
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
                    DropdownRow {
                        opacity: monOn ? 1 : 0.45
                        title: "Resolution"
                        selected: root.tab === 2 && root.selectedIndex === root.monFirst + index * root.monRows + 2
                        onHovered: {
                            if (!root.anyDropOpen())
                                root.selectedIndex = root.monFirst + index * root.monRows + 2;
                        }
                        z: root.openMonRes === monName ? 100 : 0
                        options: Services.Settings.monitorModes(monName)
                        current: Services.Settings.monitorRes(monName)
                        dropOpen: root.openMonRes === monName
                        cursor: root.dropCursor
                        openUp: index === root.monCount - 1
                        onHeaderClicked: {
                            root.selectedIndex = root.monFirst + index * root.monRows + 2;
                            root.toggleMonDrop(monName);
                        }
                        onOptionHovered: optIdx => root.dropCursor = optIdx
                        onOptionClicked: value => {
                            root.selectedIndex = root.monFirst + index * root.monRows + 2;
                            root.commitMonRes(monName, value);
                        }
                    }
                    DropdownRow {
                        opacity: monOn ? 1 : 0.45
                        title: "Position"
                        selected: root.tab === 2 && root.selectedIndex === root.monFirst + index * root.monRows + 3
                        onHovered: {
                            if (!root.anyDropOpen())
                                root.selectedIndex = root.monFirst + index * root.monRows + 3;
                        }
                        z: root.openMonPos === monName ? 100 : 0
                        options: Services.Settings.monitorPosOptions()
                        current: Services.Settings.monitorPos(monName)
                        dropOpen: root.openMonPos === monName
                        cursor: root.dropCursor
                        openUp: index === root.monCount - 1
                        onHeaderClicked: {
                            root.selectedIndex = root.monFirst + index * root.monRows + 3;
                            root.toggleMonPosDrop(monName);
                        }
                        onOptionHovered: optIdx => root.dropCursor = optIdx
                        onOptionClicked: value => {
                            root.selectedIndex = root.monFirst + index * root.monRows + 3;
                            root.commitMonPos(monName, value);
                        }
                    }
                        }
                    }
                }
            }
            PopupButton {
                label: "Re-detect displays"
                columns: 1
                selected: root.tab === 2 && root.selectedIndex === root.monLastIndex()
                onHovered: {
                    if (!root.anyDropOpen())
                        root.selectedIndex = root.monLastIndex();
                }
                onClicked: {
                    root.selectedIndex = root.monLastIndex();
                    Services.Settings.refreshMonitors(true);
                }
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
            text: "1-3 tabs · jk move · hl adjust · ↵ open/pick"
        }
    }
}
