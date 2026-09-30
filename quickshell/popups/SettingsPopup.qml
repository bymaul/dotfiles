import QtQuick
import "../components"
import "../services" as Services
import "../services/SettingsUtil.js" as SettingsUtil
import "settings"
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
    Connections {
        target: Services.Asus
        function onAvailableChanged(): void {
            root.keepSysRow();
            root.clampSelection();
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
        root.syncLastAsusRows();
        if (root.visible && root.tab === 2)
            Services.Settings.refreshMonitors(false);
        if (root.visible && root.tab === 1)
            Services.Asus.refresh();
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
            root.syncLastAsusRows();
            Services.Settings.refreshWallpapers(false);
            if (root.tab === 2)
                Services.Settings.refreshMonitors(false);
            if (root.tab === 1)
                Services.Asus.refresh();
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
            return 11 + root.asusRows;
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
    property int lastAsusRows: 0
    // The Asus charge-limit row appears at index 4 once asusctl is detected,
    // pushing every row below it down one slot. Keep the highlight on the same
    // logical row instead of the same absolute index.
    function keepSysRow(): void {
        const delta = root.asusRows - root.lastAsusRows;
        root.lastAsusRows = root.asusRows;
        if (delta === 0 || root.tab !== 1)
            return;
        root.closeDrop();
        if (root.selectedIndex >= 4)
            root.selectedIndex = Math.max(4, root.selectedIndex + delta);
    }
    function syncLastAsusRows(): void {
        root.lastAsusRows = root.asusRows;
    }
    function syncWallCursor(): void {
        root.clampSelection();
        if (root.tab === 0 && selectedIndex >= 1 && selectedIndex <= root.wpCount)
            generalTab.wallList.currentIndex = selectedIndex - 1;
        else
            generalTab.wallList.currentIndex = -1;
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
            root.moveCursor(SettingsUtil.monitorPosOptions(), dir);
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
            if (root.asusRows === 1 && selectedIndex === 4) {
                Services.Asus.setChargeLimit(Services.Asus.chargeLimit + dir * 5);
                return;
            }
            // Idle rows 0-3 sit before the Asus charge-limit row and take no
            // offset; rows below it shift by asusRows.
            const rel = selectedIndex >= 4 + root.asusRows ? selectedIndex - root.asusRows : selectedIndex;
            switch (rel) {
            case 0: Services.Settings.setDimTimeout(Services.Settings.dimTimeout + dir * 30); break;
            case 1: Services.Settings.setLockTimeout(Services.Settings.lockTimeout + dir * 60); break;
            case 2: Services.Settings.setScreenOffTimeout(Services.Settings.screenOffTimeout + dir * 60); break;
            case 3: Services.Settings.setSuspendTimeout(Services.Settings.suspendTimeout + dir * 300); break;
            case 4: Services.Settings.setLowBatteryPct(Services.Settings.lowBatteryPct + dir * 5); break;
            case 5: Services.Settings.setCriticalBatteryPct(Services.Settings.criticalBatteryPct + dir * 2); break;
            case 6: Services.Settings.setCriticalBatteryMins(Services.Settings.criticalBatteryMins + dir * 5); break;
            case 7: Services.Settings.setCriticalBatteryAction(SettingsUtil.cycleOpt(Services.Power.criticalOptions, Services.Settings.criticalBatteryAction, dir)); break;
            case 8: Services.Settings.setLidCloseAction(SettingsUtil.cycleOpt(Services.Power.lidOptions, Services.Settings.lidCloseAction, dir)); break;
            case 9: root.cycleActiveProfile(dir); break;
            case 10: Services.Settings.setPowerProfileOnBattery(SettingsUtil.cycleOpt(Services.Power.profileOptions, Services.Settings.powerProfileOnBattery, dir)); break;
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

    function cycleActiveProfile(dir: int): void {
        if (Services.Asus.available) {
            Services.Asus.cycleProfile(dir);
            return;
        }
        if (!Services.Power.profilesAvailable)
            return;
        const order = Services.Power.hasPerformanceProfile ? ["balanced", "powersaver", "performance"] : ["balanced", "powersaver"];
        Services.Power.setProfileByName(SettingsUtil.cycleOpt(order, Services.Power.profileName, dir), false);
    }

    function activeProfileOptions(): var {
        if (Services.Asus.available)
            return Services.Asus.profileOptions;
        return Services.Power.hasPerformanceProfile ? ["balanced", "powersaver", "performance"] : ["balanced", "powersaver"];
    }
    function isDropdownIndex(i: int): bool {
        return root.tab === 1 && i >= root.sysIdx(7) && i <= root.sysIdx(10);
    }
    function dropEnabled(i: int): bool {
        if (i === root.sysIdx(9))
            return Services.Asus.available || Services.Power.profilesAvailable;
        return true;
    }
    function dropdownOptions(i: int): var {
        if (i === root.sysIdx(7))
            return Services.Power.criticalOptions;
        if (i === root.sysIdx(8))
            return Services.Power.lidOptions;
        if (i === root.sysIdx(9))
            return root.activeProfileOptions();
        if (i === root.sysIdx(10))
            return Services.Power.profileOptions;
        return [];
    }
    function dropdownCurrent(i: int): string {
        if (i === root.sysIdx(7))
            return Services.Settings.criticalBatteryAction;
        if (i === root.sysIdx(8))
            return Services.Settings.lidCloseAction;
        if (i === root.sysIdx(9)) {
            if (Services.Asus.available)
                return Services.Asus.profile !== "" ? Services.Asus.profile : "…";
            return Services.Power.profilesAvailable ? Services.Power.profileName : "no ppd";
        }
        if (i === root.sysIdx(10))
            return Services.Power.profilesAvailable ? Services.Settings.powerProfileOnBattery : "no ppd";
        return "";
    }
    function applyDropValue(i: int, value: string): void {
        if (i === root.sysIdx(7))
            Services.Settings.setCriticalBatteryAction(value);
        else if (i === root.sysIdx(8))
            Services.Settings.setLidCloseAction(value);
        else if (i === root.sysIdx(9)) {
            if (Services.Asus.available)
                Services.Asus.setProfile(value, false);
            else if (Services.Power.profilesAvailable)
                Services.Power.setProfileByName(value, false);
        } else if (i === root.sysIdx(10))
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
        const opts = SettingsUtil.monitorPosOptions();
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
        const opts = SettingsUtil.monitorPosOptions();
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
        Services.Settings.setMainMonitor(SettingsUtil.cycleOpt(opts, Services.Settings.mainMonitor, dir));
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
    property int sysBattH: (5 + root.asusRows) * Services.Theme.rowHeight + (4 + root.asusRows) * Services.Theme.listSpacing
    property int sysProfH: 2 * Services.Theme.rowHeight + Services.Theme.listSpacing
    // Extra System-tab rows inserted above the Battery section when asusd is
    // present. Battery/Profile row indices below shift by this offset.
    property int asusRows: Services.Asus.available ? 1 : 0
    function sysIdx(n: int): int {
        return n + root.asusRows;
    }
    function contentHeight(): int {
        if (root.tab === 0)
            return root.sectionH + Services.Theme.popupSpacing + root.wallColH + Services.Theme.popupSpacing + root.sectionH + Services.Theme.popupSpacing + root.inputColH;
        if (root.tab === 1) {
            let h = root.sysIdleH + root.sysBattH + root.sysProfH + 3 * root.sectionH + 30 + 6 * Services.Theme.popupSpacing;
            return h;
        }
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

        GeneralTab {
            id: generalTab
            popup: root
        }

        SystemTab {
            popup: root
        }

        DisplaysTab {
            popup: root
        }

        HintText {
            id: hint
            text: "1-3 tabs · jk move · hl adjust · ↵ open/pick"
        }
    }
}
