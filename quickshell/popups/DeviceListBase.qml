import QtQuick
import "../services" as Services
BasePopup {
    id: list
    property int headIndex: -1
    property bool listBlocked: false
    property var targetList: null
    function stepSelection(dir: int): void {
        headIndex = -1;
        stepListView(targetList, dir);
    }
    function selectRow(i: int): void {
        headIndex = -1;
        selectInList(targetList, i);
    }
    function moveHeader(dir: int): void {
        if (headIndex < 0)
            return;
        headIndex = Services.Theme.clamp(headIndex + dir, 0, 1);
    }
    function focusNext(): void {
        headIndex = headIndex >= 1 ? -1 : headIndex + 1;
    }
    function focusPrev(): void {
        headIndex = headIndex <= -1 ? 1 : headIndex - 1;
    }
    function activateSelected(): void {
        if (headIndex === 0) {
            list.toggleEnabled();
            return;
        }
        if (headIndex === 1) {
            list.toggleScan();
            return;
        }
        list.activateRow();
    }
    function activateRow(): void {
    }
    function forgetRow(): void {
    }
    function toggleEnabled(): void {
    }
    function toggleScan(): void {
    }
    function resetNav(): void {
        headIndex = -1;
        if (targetList)
            targetList.currentIndex = 0;
    }
    Shortcut { sequence: "j"; enabled: list.visible && !list.listBlocked; onActivated: list.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: list.visible && !list.listBlocked; onActivated: list.stepSelection(-1) }
    Shortcut { sequence: "Down"; enabled: list.visible && !list.listBlocked; onActivated: list.stepSelection(1) }
    Shortcut { sequence: "Up"; enabled: list.visible && !list.listBlocked; onActivated: list.stepSelection(-1) }
    Shortcut { sequence: "Left"; enabled: list.visible && !list.listBlocked; onActivated: list.moveHeader(-1) }
    Shortcut { sequence: "Right"; enabled: list.visible && !list.listBlocked; onActivated: list.moveHeader(1) }
    Shortcut { sequence: "Tab"; enabled: list.visible && !list.listBlocked; onActivated: list.focusNext() }
    Shortcut { sequence: "Shift+Tab"; enabled: list.visible && !list.listBlocked; onActivated: list.focusPrev() }
    Shortcut { sequence: "Return"; enabled: list.visible && !list.listBlocked; onActivated: list.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: list.visible && !list.listBlocked; onActivated: list.activateSelected() }
    Shortcut { sequence: "Space"; enabled: list.visible && !list.listBlocked; onActivated: list.activateSelected() }
    Shortcut { sequence: "d"; enabled: list.visible && !list.listBlocked; onActivated: list.forgetRow() }
    Shortcut { sequence: "Delete"; enabled: list.visible && !list.listBlocked; onActivated: list.forgetRow() }
    Shortcut { sequence: "s"; enabled: list.visible && !list.listBlocked; onActivated: list.toggleScan() }
    Shortcut { sequence: "e"; enabled: list.visible && !list.listBlocked; onActivated: list.toggleEnabled() }
}
