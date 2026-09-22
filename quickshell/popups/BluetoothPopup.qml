import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../components"
import "../services" as Services
BasePopup {
    id: root
    implicitWidth: Services.Theme.popupWidth
    implicitHeight: 36 + 36 + Services.Theme.listHeight(Services.Theme.listVisible) + Services.Theme.popupSpacing * 3 + 16 + hint.implicitHeight
    Shortcut { sequence: "j"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "k"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Down"; enabled: root.visible; onActivated: root.stepSelection(1) }
    Shortcut { sequence: "Up"; enabled: root.visible; onActivated: root.stepSelection(-1) }
    Shortcut { sequence: "Left"; enabled: root.visible; onActivated: root.moveHeader(-1) }
    Shortcut { sequence: "Right"; enabled: root.visible; onActivated: root.moveHeader(1) }
    Shortcut { sequence: "Tab"; enabled: root.visible; onActivated: root.focusNext() }
    Shortcut { sequence: "Shift+Tab"; enabled: root.visible; onActivated: root.focusPrev() }
    Shortcut { sequence: "Return"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Enter"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "Space"; enabled: root.visible; onActivated: root.activateSelected() }
    Shortcut { sequence: "e"; enabled: root.visible; onActivated: root.toggleAdapter() }
    Shortcut { sequence: "s"; enabled: root.visible; onActivated: root.toggleScan() }
    Shortcut { sequence: "d"; enabled: root.visible; onActivated: root.forgetSelected() }
    Shortcut { sequence: "Delete"; enabled: root.visible; onActivated: root.forgetSelected() }
    Shortcut { sequence: "t"; enabled: root.visible; onActivated: root.toggleTrust() }
    property int headIndex: -1
    property string opMessage: ""
    property bool opError: false
    property var rawDevices: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.devices && Bluetooth.defaultAdapter.devices.values) ? Bluetooth.defaultAdapter.devices.values : []
    property var sortedDevices: {
        const devs = root.rawDevices.slice();
        function rank(d) {
            if (!d)
                return 3;
            if (d.connected || d.state === BluetoothDeviceState.Connected)
                return 0;
            if (d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting)
                return 1;
            if (d.address !== "" && d.address === root.pendingAddr)
                return 1;
            if (d.paired || d.trusted)
                return 2;
            return 3;
        }
        function labelOf(d) {
            const n = (d.name || d.deviceName || d.address || "").toLowerCase();
            return n;
        }
        devs.sort(function (a, b) {
            const r = rank(a) - rank(b);
            if (r !== 0)
                return r;
            const la = labelOf(a);
            const lb = labelOf(b);
            if (la < lb)
                return -1;
            if (la > lb)
                return 1;
            const aa = (a && a.address) ? a.address : "";
            const ab = (b && b.address) ? b.address : "";
            if (aa < ab)
                return -1;
            if (aa > ab)
                return 1;
            return 0;
        });
        return devs;
    }
    onVisibleChanged: {
        if (visible) {
            headIndex = -1;
            btList.currentIndex = 0;
            root.clearOp();
        } else {
            opClear.stop();
        }
    }
    function stepSelection(dir: int): void {
        headIndex = -1;
        stepListView(btList, dir);
    }
    function selectRow(i: int): void {
        headIndex = -1;
        selectInList(btList, i);
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
            root.toggleAdapter();
            return;
        }
        if (headIndex === 1) {
            root.toggleScan();
            return;
        }
        root.activateDevice(root.selectedDevice());
    }
    function selectedDevice(): var {
        const devs = root.sortedDevices;
        if (btList.currentIndex < 0 || btList.currentIndex >= devs.length)
            return null;
        return devs[btList.currentIndex];
    }
    function activateDevice(device: var): void {
        if (!device)
            return;
        if (device.pairing) {
            device.cancelPair();
            if (device.address === root.pendingAddr)
                root.clearPending();
            root.setOp("Pairing cancelled", false);
            return;
        }
        if (device.connected || device.state === BluetoothDeviceState.Connected) {
            if (device.address === root.pendingAddr)
                root.clearPending();
            root.setOp("Disconnecting " + root.deviceLabel(device) + "...", false);
            device.disconnect();
            return;
        }
        if (device.paired || device.bonded) {
            root.pendingAddr = device.address;
            root.pendingAuto = false;
            root.pendingSince = Date.now();
            opWatch.restart();
            root.setOp("Connecting " + root.deviceLabel(device) + "...", false);
            console.log("[bt] connect " + device.address);
            device.connect();
            return;
        }
        const adapter = Bluetooth.defaultAdapter;
        if (adapter) {
            if (!adapter.enabled)
                adapter.enabled = true;
            adapter.pairable = true;
            if (!adapter.discovering) {
                adapter.discovering = true;
                scanTimeout.restart();
            }
        }
        if (!device.trusted)
            device.trusted = true;
        root.pendingAddr = device.address;
        root.pendingAuto = true;
        root.pendingSince = Date.now();
        opWatch.restart();
        root.setOp("Pairing " + root.deviceLabel(device) + "...", false);
        console.log("[bt] pair start " + device.address);
        device.pair();
    }
    property string pendingAddr: ""
    property bool pendingAuto: false
    property double pendingSince: 0
    readonly property int pairTimeoutMs: 30000
    readonly property int connectTimeoutMs: 12000
    function findDevice(addr: string): var {
        if (addr === "")
            return null;
        const devs = root.sortedDevices;
        for (let i = 0; i < devs.length; i++) {
            const d = devs[i];
            if (d && d.address === addr)
                return d;
        }
        return null;
    }
    function deviceLabel(dev: var): string {
        if (!dev)
            return "";
        return dev.name || dev.deviceName || dev.address;
    }
    function clearPending(): void {
        root.pendingAddr = "";
        root.pendingAuto = false;
        root.pendingSince = 0;
        opWatch.stop();
    }
    function setOp(msg: string, isError: bool): void {
        root.opMessage = msg;
        root.opError = isError;
        if (isError)
            opClear.stop();
        else
            opClear.restart();
    }
    function clearOp(): void {
        opClear.stop();
        root.opMessage = "";
        root.opError = false;
    }
    function failPending(dev: var, what: string): void {
        const name = root.deviceLabel(dev);
        if (what === "Pairing")
            root.setOp("Pairing failed" + (name !== "" ? ": " + name : "") + " - retry scan", true);
        else
            root.setOp("Connect failed" + (name !== "" ? ": " + name : "") + " - retry", true);
        root.clearPending();
    }
    function toggleAdapter(): void {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
            root.clearOp();
        }
    }
    function toggleScan(): void {
        if (!Bluetooth.defaultAdapter)
            return;
        Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering;
        if (Bluetooth.defaultAdapter.discovering)
            scanTimeout.restart();
        else
            scanTimeout.stop();
    }
    Timer {
        id: opClear
        interval: 5000
        repeat: false
        onTriggered: root.clearOp()
    }
    Timer {
        id: scanTimeout
        interval: Services.Theme.scanTimeout
        repeat: false
        onTriggered: {
            if (root.pendingAddr !== "") {
                if (Bluetooth.defaultAdapter && !Bluetooth.defaultAdapter.discovering)
                    Bluetooth.defaultAdapter.discovering = true;
                scanTimeout.restart();
                return;
            }
            if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.discovering = false;
        }
    }
    Timer {
        id: opWatch
        interval: 500
        repeat: true
        onTriggered: {
            if (root.pendingAddr === "") {
                opWatch.stop();
                return;
            }
            const dev = root.findDevice(root.pendingAddr);
            if (!dev) {
                root.setOp("Device lost - scan again", true);
                root.clearPending();
                return;
            }
            const elapsed = Date.now() - root.pendingSince;
            if (root.pendingAuto) {
                if ((dev.paired || dev.bonded) && !dev.pairing) {
                    console.log("[bt] paired " + dev.address + ", connecting");
                    if (!dev.trusted)
                        dev.trusted = true;
                    root.pendingAuto = false;
                    root.pendingSince = Date.now();
                    root.setOp("Paired, connecting " + root.deviceLabel(dev) + "...", false);
                    dev.connect();
                    return;
                }
                if (elapsed > root.pairTimeoutMs) {
                    if (dev.pairing)
                        dev.cancelPair();
                    root.failPending(dev, "Pairing");
                }
                return;
            }
            if (dev.connected || dev.state === BluetoothDeviceState.Connected) {
                console.log("[bt] connected " + dev.address);
                root.setOp("Connected: " + root.deviceLabel(dev), false);
                root.clearPending();
                return;
            }
            if (elapsed > root.connectTimeoutMs)
                root.failPending(dev, "Connect");
        }
    }
    function forgetSelected(): void {
        const dev = root.selectedDevice();
        if (dev && (dev.paired || dev.bonded) && !(dev.connected || dev.state === BluetoothDeviceState.Connected)) {
            if (dev.address === root.pendingAddr)
                root.clearPending();
            root.setOp("Forgot " + root.deviceLabel(dev), false);
            dev.forget();
        }
    }
    function toggleTrust(): void {
        const dev = root.selectedDevice();
        if (dev)
            dev.trusted = !dev.trusted;
    }
    function statusText(dev: var): string {
        let s = "Available";
        const isConnected = dev.connected || dev.state === BluetoothDeviceState.Connected;
        if (dev.address !== "" && dev.address === root.pendingAddr && root.pendingAuto)
            s = "Pairing... confirm on device if asked";
        else if (dev.address !== "" && dev.address === root.pendingAddr && !root.pendingAuto && !isConnected)
            s = "Connecting...";
        else if (dev.blocked)
            s = "Blocked";
        else if (isConnected)
            s = "Connected";
        else if (dev.state === BluetoothDeviceState.Connecting)
            s = "Connecting...";
        else if (dev.state === BluetoothDeviceState.Disconnecting)
            s = "Disconnecting...";
        else if (dev.pairing)
            s = "Pairing...";
        const tags = [];
        if (dev.trusted)
            tags.push("Trusted");
        if (dev.batteryAvailable)
            tags.push(Math.round(dev.battery * 100) + "%");
        if (dev.address !== "")
            tags.push(dev.address);
        if (tags.length > 0)
            s += " · " + tags.join(" · ");
        return s;
    }
    function headerStatus(): string {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter)
            return "No Bluetooth adapter found";
        if (!adapter.enabled)
            return "Bluetooth is off";
        const devs = root.sortedDevices;
        let connected = 0;
        let paired = 0;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i] && (devs[i].connected || devs[i].state === BluetoothDeviceState.Connected))
                connected++;
            else if (devs[i] && (devs[i].paired || devs[i].bonded))
                paired++;
        }
        if (connected > 0 && paired > 0)
            return connected + " connected · " + paired + " paired";
        if (connected > 0)
            return connected === 1 ? "1 connected" : connected + " connected";
        if (paired > 0)
            return paired === 1 ? "1 paired · not connected" : paired + " paired · not connected";
        if (devs.length > 0)
            return "Not connected";
        if (adapter.discovering)
            return "Scanning for devices...";
        return "No devices found";
    }
    PopupCard {
        Rectangle {
            width: parent.width
            height: Services.Theme.rowHeight
            color: "transparent"
            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                }
                width: parent.width - 20
                text: root.opMessage !== "" ? root.opMessage : root.headerStatus()
                color: root.opMessage !== "" ? (root.opError ? Services.Theme.danger : Services.Theme.fg) : Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
                elide: Text.ElideRight
            }
        }
        Row {
            width: parent.width
            height: Services.Theme.rowHeight
            spacing: Services.Theme.popupSpacing
            PopupButton {
                label: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "󰂲  Disable" : "󰂯  Enable"
                selected: root.headIndex === 0
                onHovered: root.headIndex = 0
                onClicked: root.toggleAdapter()
            }
            PopupButton {
                label: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "󰑓  Scanning..." : "󰑐  Scan"
                selected: root.headIndex === 1
                onHovered: root.headIndex = 1
                onClicked: root.toggleScan()
            }
        }
        Item {
            width: parent.width
            height: Services.Theme.listHeight(Services.Theme.listVisible)
            ListView {
                id: btList
                anchors.fill: parent
                clip: true
                model: root.sortedDevices
                spacing: Services.Theme.listSpacing
                onCountChanged: clampListView(btList)
                delegate: ResultRow {
                    id: row
                    required property var modelData
                    required property int index
                    selected: btList.currentIndex === index
                    highlighted: row.connected
                    rowHeight: Services.Theme.listRowHeight
                    selectedColor: Services.Theme.activeBg
                    readonly property bool connected: modelData.connected || modelData.state === BluetoothDeviceState.Connected
                    onHovered: root.selectRow(index)
                    onClicked: root.activateDevice(modelData)
                    Row {
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: Services.Theme.popupSpacing
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            text: row.connected ? "󰂯" : "󰂲"
                            color: row.selected ? Services.Theme.fg : row.connected ? Services.Theme.accent : row.isHovered ? Services.Theme.fg : Services.Theme.dim
                            font.family: Services.Theme.font
                            font.pixelSize: Services.Theme.px13
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 58
                            spacing: 2
                            Text {
                                width: parent.width
                                text: modelData.name || modelData.deviceName || "Unknown device"
                                color: row.selected ? Services.Theme.fg : (row.connected || row.isHovered) ? Services.Theme.fg : Services.Theme.dim
                                font.family: Services.Theme.font
                                font.pixelSize: Services.Theme.px12
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: root.statusText(modelData)
                                color: row.selected ? Services.Theme.fg : row.isHovered ? Services.Theme.fg : Services.Theme.dim
                                font.family: Services.Theme.font
                                font.pixelSize: Services.Theme.px10
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            horizontalAlignment: Text.AlignHCenter
                            text: "󰅖"
                            color: row.selected ? Services.Theme.fg : forgetArea.containsMouse ? Services.Theme.fg : Services.Theme.dim
                            font.family: Services.Theme.font
                            font.pixelSize: Services.Theme.px13
                            visible: (modelData.paired || modelData.bonded) && !row.connected
                            MouseArea {
                                id: forgetArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    mouse.accepted = true;
                                    root.forgetSelected();
                                }
                            }
                        }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: !Bluetooth.defaultAdapter
                text: "No Bluetooth adapter"
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
            }
            Text {
                anchors.centerIn: parent
                visible: Bluetooth.defaultAdapter && !Bluetooth.defaultAdapter.enabled
                text: "󰂲  Bluetooth is off · press e to enable"
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
            }
            Text {
                anchors.centerIn: parent
                visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled && root.sortedDevices.length === 0
                text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "Scanning..." : "No devices · press s to scan"
                color: Services.Theme.dim
                font.family: Services.Theme.font
                font.pixelSize: Services.Theme.px12
            }
        }
        HintText {
            id: hint
            text: "jk move · Tab header · ↵ connect · d forget · t trust · s scan · e on/off"
        }
    }
}
