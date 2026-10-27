import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../components"
import "../../services" as Services

Rectangle {
    id: root
    required property var popup

    property bool expanded: false
    property int listIndex: 0
    property var currentMenu: null
    property var menuOwner: null
    property var menuStack: []
    readonly property bool inMenu: currentMenu !== null

    readonly property var entries: root.inMenu ? menuOpener.children.values : SystemTray.items.values
    readonly property int entryCount: root.entries.length
    readonly property int listCap: 6 * 28 + 5 * Services.Theme.listSpacing

    readonly property int listHeight: {
        if (!root.expanded || root.entryCount === 0)
            return 0;
        let h = -Services.Theme.listSpacing;
        for (const e of root.entries)
            h += root.rowHeight(e) + Services.Theme.listSpacing;
        return h;
    }

    visible: root.entryCount > 0
    width: parent.width
    color: popup.selectedKind() === "tray" ? Services.Theme.activeBg : Services.Theme.surface

    readonly property real contentBottom: {
        let bottom = 0;
        for (const c of shellCol.children)
            if (c.visible)
                bottom = Math.max(bottom, c.y + c.height);
        return bottom;
    }

    height: visible ? (root.expanded ? Math.max(Services.Theme.rowHeight, root.contentBottom) : Services.Theme.rowHeight) : 0
    clip: true

    onListIndexChanged: if (expanded)
        entryList.positionViewAtIndex(listIndex, ListView.Contain)

    function resetState() {
        root.expanded = false;
        root.listIndex = 0;
        root.currentMenu = null;
        root.menuOwner = null;
        root.menuStack = [];
    }

    function selectable(e: var): bool {
        if (!e)
            return false;
        if (root.inMenu)
            return !e.isSeparator && e.enabled !== false;
        return true;
    }

    function clean(text: string): string {
        return (text ?? "").replace(/&([^&])/g, "$1").trim();
    }

    function rowHeight(e: var): int {
        return (e?.isSeparator ?? false) ? 6 : 28;
    }

    function labelFor(e: var): string {
        if (!e)
            return "";
        if (root.inMenu)
            return root.clean(e.text);
        return root.trayLabel(e);
    }

    function trayLabel(e: var): string {
        if (!e)
            return "";
        for (const s of [root.clean(e.tooltipTitle), root.clean(e.title), root.clean(e.id)]) {
            if (s !== "")
                return s;
        }
        return "";
    }

    function currentEntry(): var {
        return root.entries[root.listIndex] ?? null;
    }

    function clampIndex() {
      if (root.entryCount === 0) {
            listIndex = 0;
            return;
        }
        if (listIndex >= root.entryCount)
            listIndex = root.entryCount - 1;
        if (!root.selectable(root.currentEntry())) {
            for (let i = 0; i < root.entryCount; i++) {
                if (root.selectable(root.entries[i])) {
                    listIndex = i;
                    return;
                }
            }
        }
    }

    function moveInList(dir: int) {
        if (root.entryCount === 0)
            return;
        let i = root.listIndex;
        for (let step = 0; step < root.entryCount; step++) {
            i = (i + dir + root.entryCount) % root.entryCount;
            if (root.selectable(root.entries[i])) {
                listIndex = i;
                return;
            }
        }
    }

    function openMenuFor(item: var) {
        if (!item || !item.hasMenu)
            return;
        root.menuOwner = item;
        root.menuStack = [];
        root.currentMenu = item.menu;
        root.listIndex = 0;
        root.clampIndex();
    }

    function diveSubmenu(entry: var) {
        if (!entry || !entry.hasChildren)
            return;
        root.menuStack = [...root.menuStack, { menu: root.currentMenu, label: root.labelFor(entry) }];
        root.currentMenu = entry;
        root.listIndex = 0;
        root.clampIndex();
    }

    function collapse() {
        root.currentMenu = null;
        root.menuOwner = null;
        root.menuStack = [];
        root.expanded = false;
        root.listIndex = 0;
    }

    function activate() {
        if (!root.expanded) {
            root.expanded = true;
            root.clampIndex();
            return;
        }
        const e = root.currentEntry();
        if (!e)
            return;
        if (!root.inMenu) {
            if (e.hasMenu) {
                root.openMenuFor(e);
            } else {
                try {
                    if (e.onlyMenu && typeof e.secondaryActivate === "function")
                        e.secondaryActivate();
                    else
                        e.activate();
                } catch (_) {}
                root.collapse();
            }
        } else if (e.hasChildren) {
            root.diveSubmenu(e);
        } else {
            try {
                e.triggered();
            } catch (_) {}
            root.collapse();
        }
    }

    function forward() {
        if (!root.expanded) {
            root.activate();
            return;
        }
        const e = root.currentEntry();
        if (!e)
            return;
        if (!root.inMenu) {
            if (e.hasMenu)
                root.openMenuFor(e);
        } else if (e.hasChildren) {
            root.diveSubmenu(e);
        }
    }

    function back() {
        if (!root.expanded)
            return false;
        const level = root.menuStack.pop() ?? null;
        if (level) {
            root.currentMenu = level.menu;
            root.listIndex = 0;
            root.clampIndex();
        } else if (root.inMenu) {
            root.currentMenu = null;
            root.menuOwner = null;
            root.menuStack = [];
            root.listIndex = 0;
            root.clampIndex();
        } else {
            root.collapse();
        }
        return true;
    }

    function secondaryActivateAt(index: int) {
        const item = root.entries[index] ?? null;
        if (!item)
            return;
        try {
            if (typeof item.secondaryActivate === "function")
                item.secondaryActivate();
            else if (typeof item.activate === "function")
                item.activate();
        } catch (_) {}
    }

    QsMenuOpener {
        id: menuOpener
        menu: root.currentMenu
    }

    MouseArea {
        anchors.fill: parent
        visible: !root.expanded
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (containsMouse && root.popup.visible)
                root.popup.selectTray();
        }
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.expanded = true;
                root.clampIndex();
            }
        }
    }

    Column {
        id: shellCol
        width: parent.width
        spacing: Services.Theme.listSpacing

        HintText {
            visible: root.expanded && root.inMenu
            horizontalAlignment: Text.AlignLeft
            leftPadding: 8
            topPadding: 4
            text: [root.trayLabel(root.menuOwner), ...root.menuStack.map(s => s.label)].join(" / ")
            color: root.menuStack.length > 0 ? Services.Theme.dim : Services.Theme.accent
        }

        Row {
            id: trayIcons
            visible: !root.expanded
            z: 1
            anchors.horizontalCenter: parent.horizontalCenter
            height: Services.Theme.rowHeight
            spacing: Services.Theme.tightSpacing
            Repeater {
                id: trayRepeater
                model: SystemTray.items
                delegate: Item {
                    id: trayIcon
                    required property var modelData
                    width: Services.Theme.traySize
                    height: Services.Theme.traySize
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        anchors.fill: parent
                        source: (trayIcon.modelData?.icon ?? "")
                        sourceSize.width: Services.Theme.traySize
                        sourceSize.height: Services.Theme.traySize
                        fillMode: Image.PreserveAspectFit
                        cache: true
                        asynchronous: true
                        visible: (trayIcon.modelData?.icon ?? "") !== ""
                    }
                    QsMenuAnchor {
                        id: menuAnchor
                        menu: trayIcon.modelData?.menu ?? null
                        anchor.item: trayIcon
                        anchor.edges: Edges.Bottom
                        anchor.gravity: Edges.Bottom
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            const item = trayIcon.modelData;
                            if (!item)
                                return;
                            try {
                                if (mouse.button === Qt.MiddleButton && typeof item.secondaryActivate === "function")
                                    item.secondaryActivate();
                                else if (mouse.button === Qt.LeftButton && !item.onlyMenu)
                                    item.activate();
                                else if (item.hasMenu)
                                    menuAnchor.open();
                                else
                                    item.secondaryActivate();
                            } catch (_) {}
                        }
                    }
                }
            }
        }

        ListView {
            id: entryList
            visible: root.expanded
            model: root.expanded ? root.entries : []
            width: root.width
            height: visible ? Math.min(root.listHeight, root.listCap) : 0
            spacing: Services.Theme.listSpacing
            clip: true
            interactive: false

            onModelChanged: {
                contentY = 0;
                positionViewAtIndex(root.listIndex, ListView.Contain);
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            }

            delegate: Item {
                id: entryRow
                required property var modelData
                required property int index

                width: root.width
                height: root.rowHeight(entryRow.modelData)
                readonly property bool isSel: root.expanded && index === root.listIndex && !entryRow.isSep
                readonly property bool dimSel: root.inMenu && ((entryRow.modelData?.enabled ?? true) === false)
                readonly property bool isSep: entryRow.modelData?.isSeparator ?? false

                onIsSelChanged: {
                    if (isSel && root.popup.visible)
                        root.popup.selectTray();
                }

                Rectangle {
                    visible: entryRow.isSep
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 10
                    height: 1
                    color: Services.Theme.border
                }

                Rectangle {
                    visible: !entryRow.isSep
                    anchors.fill: parent
                    color: entryRow.isSel ? Services.Theme.accent : "transparent"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse && root.selectable(entryRow.modelData))
                                root.listIndex = entryRow.index;
                        }
                        onClicked: mouse => {
                            if (!root.selectable(entryRow.modelData))
                                return;
                            root.listIndex = entryRow.index;
                            if (mouse.button === Qt.RightButton) {
                                if (!root.inMenu)
                                    root.secondaryActivateAt(entryRow.index);
                                else
                                    root.back();
                            } else if (mouse.button === Qt.LeftButton) {
                                root.activate();
                            }
                        }
                    }

                    Row {
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: Services.Theme.popupSpacing

                        Image {
                            visible: !root.inMenu && (entryRow.modelData?.icon ?? "") !== ""
                            anchors.verticalCenter: parent.verticalCenter
                            width: Services.Theme.traySize
                            height: Services.Theme.traySize
                            fillMode: Image.PreserveAspectFit
                            cache: true
                            asynchronous: true
                            source: entryRow.modelData?.icon ?? ""
                            sourceSize.width: Services.Theme.traySize
                            sourceSize.height: Services.Theme.traySize
                            opacity: entryRow.dimSel ? 0.4 : 1
                        }

                        Text {
                            width: parent.width - (root.inMenu ? 0 : parent.spacing + Services.Theme.traySize)
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.labelFor(entryRow.modelData)
                            elide: Text.ElideRight
                            color: entryRow.isSel ? Services.Theme.accentFg : entryRow.dimSel ? Services.Theme.dim : Services.Theme.fg
                            opacity: entryRow.dimSel ? 0.5 : 1
                            font.family: Services.Theme.font
                            font.pixelSize: Services.Theme.px12
                        }
                    }
                }
            }
        }

        Text {
            visible: root.expanded && root.entryCount === 0
            width: root.width
            horizontalAlignment: Text.AlignHCenter
            text: "No tray items"
            color: Services.Theme.dim
            font.family: Services.Theme.font
            font.pixelSize: Services.Theme.px12
            topPadding: 10
            bottomPadding: 10
        }
    }
}
