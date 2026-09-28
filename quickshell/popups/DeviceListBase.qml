import QtQuick
BasePopup {
    id: list
    property bool listBlocked: false
    property var targetList: null
    function stepSelection(dir: int): void {
        stepListView(targetList, dir);
    }
    function selectRow(i: int): void {
        selectInList(targetList, i);
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
        if (targetList)
            targetList.currentIndex = 0;
    }
    Shortcut { sequence: "j"; enabled: list.visible && !list.listBlocked; onActivated: list.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: list.visible && !list.listBlocked; onActivated: list.stepSelection(-1) }
    Shortcut { sequence: "Down"; enabled: list.visible && !list.listBlocked; onActivated: list.stepSelection(1) }
    Shortcut { sequence: "Up"; enabled: list.visible && !list.listBlocked; onActivated: list.stepSelection(-1) }
    Shortcut { sequence: "Return"; enabled: list.visible && !list.listBlocked; onActivated: list.activateRow() }
    Shortcut { sequence: "Enter"; enabled: list.visible && !list.listBlocked; onActivated: list.activateRow() }
    Shortcut { sequence: "Space"; enabled: list.visible && !list.listBlocked; onActivated: list.activateRow() }
    Shortcut { sequence: "d"; enabled: list.visible && !list.listBlocked; onActivated: list.forgetRow() }
    Shortcut { sequence: "Delete"; enabled: list.visible && !list.listBlocked; onActivated: list.forgetRow() }
    Shortcut { sequence: "s"; enabled: list.visible && !list.listBlocked; onActivated: list.toggleScan() }
    Shortcut { sequence: "e"; enabled: list.visible && !list.listBlocked; onActivated: list.toggleEnabled() }
}
