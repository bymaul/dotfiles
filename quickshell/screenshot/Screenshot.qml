import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import "../services" as Services
import "../Palette.js" as Palette
Scope {
    id: root
    readonly property string shotDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
    readonly property var targetScreen: {
        const want = Hyprland.focusedMonitor?.name ?? "";
        return Quickshell.screens.find(s => s.name === want) ?? Quickshell.screens[0] ?? null;
    }
    property string pendingMode: ""
    property string pendingFile: ""
    property string tmpFile: "/tmp/qs-screenshot-full.png"
    property bool freezeForPicker: false
    property real lastScale: 1
    function stamp(): string {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
    }
    function capture(mode: string): void {
        root.pendingMode = mode;
        mkdir.running = true;
    }
    Process {
        id: mkdir
        command: ["mkdir", "-p", root.shotDir]
        onExited: exitCode => {
            if (exitCode !== 0)
                return;
            if (root.pendingMode === "area") {
                picker.pickMode = "area";
                picker.visible = true;
                return;
            }
            if (root.pendingMode === "window") {
                winProbe.running = true;
                return;
            }
            root.showCapture(false);
        }
    }
    function showCapture(freeze: bool): void {
        captureView.captureSource = root.targetScreen;
        if (!captureView.captureSource) {
            if (freeze)
                picker.close();
            return;
        }
        if (!freeze)
            root.pendingFile = root.shotDir + "/" + root.stamp() + ".png";
        root.freezeForPicker = freeze;
        captureWin.visible = true;
        captureTimeout.start();
    }
    function captureScreen(): void {
        root.showCapture(false);
    }
    function freezeStill(): void {
        root.showCapture(true);
    }
    Process {
        id: winProbe
        command: ["sh", "-c", "M=$(hyprctl monitors -j 2>/dev/null); W=$(hyprctl activewindow -j 2>/dev/null); [ -n \"$M\" ] && [ -n \"$W\" ] && echo \"$W\" | jq -e 'select(.address != null and .address != \"\")' >/dev/null 2>&1 && MID=$(echo \"$W\" | jq -r '.monitor // -1') && O=$(echo \"$M\" | jq -r --argjson mid \"$MID\" '([.[] | select(.id == $mid)][0] // ([.[] | select(.focused == true)][0])) | select(. != null) | \"\\(.x) \\(.y)\"') && [ -n \"$O\" ] && G=$(echo \"$W\" | jq -r '\"\\(.at[0]) \\(.at[1]) \\(.size[0]) \\(.size[1])\"') && [ -n \"$G\" ] && printf '%s %s\\n' \"$O\" \"$G\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim().match(/(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(\d+)\s+(\d+)/);
                if (!m) {
                    root.captureScreen();
                    return;
                }
                const mx = parseInt(m[1]), my = parseInt(m[2]);
                picker.winRect = Qt.rect(parseInt(m[3]) - mx, parseInt(m[4]) - my, parseInt(m[5]), parseInt(m[6]));
                picker.pickMode = "window";
                picker.visible = true;
            }
        }
    }
    PanelWindow {
        id: captureWin
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        screen: root.targetScreen
        exclusiveZone: -1
        visible: false
        color: "transparent"
        ScreencopyView {
            id: captureView
            anchors.fill: parent
            live: false
            paintCursor: false
            onHasContentChanged: {
                if (hasContent)
                    grabDelay.start();
            }
        }
        Timer {
            id: grabDelay
            interval: 400
            repeat: false
            onTriggered: {
                const src = captureView.sourceSize;
                const w = root.targetScreen?.width ?? 0;
                if (src.width > 0 && w > 0)
                    root.lastScale = src.width / w;
                captureView.grabToImage(result => {
                    captureTimeout.stop();
                    if (root.freezeForPicker) {
                        root.freezeForPicker = false;
                        if (result.saveToFile(root.tmpFile)) {
                            still.source = "file://" + root.tmpFile;
                            picker.stillReady = true;
                        } else {
                            picker.close();
                        }
                    } else if (result.saveToFile(root.pendingFile)) {
                        root.finishShot(root.pendingFile);
                    }
                    captureView.captureSource = null;
                    captureWin.visible = false;
                });
            }
        }
        Timer {
            id: captureTimeout
            interval: 5000
            repeat: false
            onTriggered: {
                if (root.freezeForPicker) {
                    root.freezeForPicker = false;
                    picker.close();
                }
                captureView.captureSource = null;
                captureWin.visible = false;
            }
        }
    }
    function finishShot(file: string): void {
        copyProc.file = file;
        copyProc.running = true;
        Services.Notifs.notify({
            app: "screenshot",
            summary: "Screenshot",
            body: file.split("/").pop(),
            icon: file,
            filepath: file,
            timeout: 10000,
            actions: [{identifier: "default", text: "Open"}, {identifier: "path", text: "Copy path"}]
        });
    }
    Process {
        id: copyProc
        property string file: ""
        command: ["sh", "-c", "wl-copy -t image/png < \"$1\"", "qs", copyProc.file]
    }
    PanelWindow {
        id: picker
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        screen: root.targetScreen
        exclusiveZone: -1
        visible: false
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-screenshot-picker"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        property bool stillReady: false
        property string pickMode: "area"
        property rect winRect: Qt.rect(0, 0, 0, 0)
        property real startX: 0
        property real startY: 0
        property rect selection: Qt.rect(0, 0, 0, 0)
        property bool selecting: false
        readonly property rect normalized: {
            const s = picker.selection;
            return Qt.rect(Math.min(s.x, s.x + s.width), Math.min(s.y, s.y + s.height), Math.abs(s.width), Math.abs(s.height));
        }
        onStillReadyChanged: {
            if (stillReady && pickMode === "window") {
                picker.selection = Qt.rect(picker.winRect.x, picker.winRect.y, picker.winRect.width, picker.winRect.height);
                picker.acceptSelection();
            }
        }
        onVisibleChanged: {
            if (visible) {
                root.freezeStill();
            } else {
                focusGrab.active = false;
                stillReady = false;
                selection = Qt.rect(0, 0, 0, 0);
                selecting = false;
                still.source = "";
            }
        }
        HyprlandFocusGrab {
            id: focusGrab
            windows: [picker]
            onCleared: picker.close()
        }
        Timer {
            id: grabTimer
            interval: Palette.grabDelay
            running: picker.visible
            repeat: false
            onTriggered: focusGrab.active = true
        }
        function close(): void {
            picker.visible = false;
        }
        function acceptSelection(): void {
            const n = picker.normalized;
            const x1 = Palette.clamp(n.x, 0, picker.width);
            const y1 = Palette.clamp(n.y, 0, picker.height);
            const x2 = Palette.clamp(n.x + n.width, 0, picker.width);
            const y2 = Palette.clamp(n.y + n.height, 0, picker.height);
            const r = Qt.rect(x1, y1, Math.max(0, x2 - x1), Math.max(0, y2 - y1));
            if (r.width < 4 || r.height < 4) {
                picker.close();
                return;
            }
            root.pendingFile = root.shotDir + "/" + root.stamp() + ".png";
            cropBox.x = r.x;
            cropBox.y = r.y;
            cropBox.width = r.width;
            cropBox.height = r.height;
            cropBox.visible = true;
            cropGrab.start();
        }
        Image {
            id: still
            anchors.fill: parent
            fillMode: Image.Stretch
            cache: false
            visible: picker.stillReady
        }
        Rectangle {
            anchors.fill: parent
            color: Palette.bg
            opacity: 0.75
            visible: picker.stillReady
        }
        MouseArea {
            anchors.fill: parent
            enabled: picker.stillReady && picker.pickMode === "area"
            hoverEnabled: picker.pickMode === "area"
            cursorShape: picker.pickMode === "area" ? Qt.CrossCursor : Qt.ArrowCursor
            acceptedButtons: Qt.LeftButton
            onPressed: mouse => {
                picker.startX = mouse.x;
                picker.startY = mouse.y;
                picker.selection = Qt.rect(mouse.x, mouse.y, 0, 0);
                picker.selecting = true;
            }
            onPositionChanged: mouse => {
                if (picker.selecting)
                    picker.selection = Qt.rect(picker.startX, picker.startY, mouse.x - picker.startX, mouse.y - picker.startY);
            }
            onReleased: mouse => {
                if (!picker.selecting)
                    return;
                picker.selecting = false;
                picker.selection = Qt.rect(picker.startX, picker.startY, mouse.x - picker.startX, mouse.y - picker.startY);
                picker.acceptSelection();
            }
        }
        Rectangle {
            x: picker.normalized.x
            y: picker.normalized.y
            width: picker.normalized.width
            height: picker.normalized.height
            visible: picker.selecting || (picker.stillReady && picker.normalized.width > 0)
            color: "transparent"
            border.width: 1
            border.color: Palette.accent
        }
        Item {
            id: cropBox
            visible: false
            Image {
                id: cropImg
                x: -cropBox.x
                y: -cropBox.y
                width: picker.width
                height: picker.height
                fillMode: Image.Stretch
                cache: false
                source: picker.stillReady ? "file://" + root.tmpFile : ""
            }
        }
        Timer {
            id: cropGrab
            interval: 250
            repeat: false
            onTriggered: {
                const r = picker.normalized;
                const k = root.lastScale;
                cropBox.grabToImage(result => {
                    cropBox.visible = false;
                    picker.close();
                    if (result.saveToFile(root.pendingFile))
                        root.finishShot(root.pendingFile);
                }, Qt.size(Math.max(1, Math.round(r.width * k)), Math.max(1, Math.round(r.height * k))));
            }
        }
        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 24
            }
            visible: picker.stillReady && !picker.selecting && picker.pickMode === "area"
            text: "drag to select · esc cancels"
            color: Palette.dim
            font.family: Palette.font
            font.pixelSize: Palette.px12
        }
        Shortcut {
            sequence: "Escape"
            enabled: picker.visible
            onActivated: picker.close()
        }
    }
}
