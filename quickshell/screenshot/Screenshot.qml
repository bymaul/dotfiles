import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import "../services" as Services
import "../Palette.js" as Palette

// In-shell screenshots (replaces grim/slurp): full screen, active
// window, or a dragged region. Saves a timestamped PNG, copies it
// to the clipboard, and toasts with Open/Copy-path actions.
// Trigger via bar.screenshot(mode); Escape cancels the picker.
Scope {
    id: root

    readonly property string shotDir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    // Screen under the focused monitor, falling back to the first.
    readonly property var targetScreen: {
        const want = Hyprland.focusedMonitor?.name ?? "";

        return Quickshell.screens.find(s => s.name === want) ?? Quickshell.screens[0] ?? null;
    }

    property string pendingMode: ""
    property string pendingFile: ""
    property string tmpFile: "/tmp/qs-screenshot-full.png"
    property bool freezeForPicker: false

    // Last known output/logical scale, captured while a source is
    // live: sourceSize reads (0,0) once the source is nulled, so
    // crop paths use this instead of recomputing too late.
    property real lastScale: 1

    function stamp(): string {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
    }

    function capture(mode: string): void {
        root.pendingMode = mode;
        mkdir.running = true;
    }

    function screenshot(mode: string): void {
        root.capture(mode);
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

            root.captureScreen();
        }
    }

    function captureScreen(): void {
        captureView.captureSource = root.targetScreen;

        if (!captureView.captureSource)
            return;

        root.pendingFile = root.shotDir + "/" + root.stamp() + ".png";
        captureWin.visible = true;
        captureTimeout.start();
    }

    // Freeze path for the picker (area + window modes): same proven
    // capture chain as full mode, but into the tmp frame the picker
    // selects on. Never the picker's own ScreencopyView: its grabs
    // come out at an unusable size.
    function freezeStill(): void {
        captureView.captureSource = root.targetScreen;

        if (!captureView.captureSource) {
            picker.close();
            return;
        }

        root.freezeForPicker = true;
        captureWin.visible = true;
        captureTimeout.start();
    }

    // Active window rect, monitor-relative in overlay (logical)
    // pixels. hyprctl reports global layout coords, so the probe
    // also resolves the window's monitor origin and subtracts it.
    // No scale division: layout coords are already logical, and the
    // crop grab multiplies back to physical with lastScale.
    Process {
        id: winProbe

        command: ["sh", "-c", "M=$(hyprctl monitors -j 2>/dev/null); W=$(hyprctl activewindow -j 2>/dev/null); [ -n \"$M\" ] && [ -n \"$W\" ] && echo \"$W\" | jq -e 'select(.address != null and .address != \"\")' >/dev/null 2>&1 && MID=$(echo \"$W\" | jq -r '.monitor // -1') && O=$(echo \"$M\" | jq -r --argjson mid \"$MID\" '([.[] | select(.id == $mid)][0] // ([.[] | select(.focused == true)][0])) | select(. != null) | \"\\(.x) \\(.y)\"') && [ -n \"$O\" ] && G=$(echo \"$W\" | jq -r '\"\\(.at[0]) \\(.at[1]) \\(.size[0]) \\(.size[1])\"') && [ -n \"$G\" ] && printf '%s %s\\n' \"$O\" \"$G\""]

        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim().match(/(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(\d+)\s+(\d+)/);

                // No active window: fall back to full screen.
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

    // Fullscreen capture surface for full mode and the picker
    // freeze frame. Fullscreen matters: grabs from small windows
    // come out shifted, and explicit grab sizes scale unpredictably,
    // so this view renders 1:1 and grabs run without a target size
    // (item pixels times output scale = source pixels, verified).
    // Transparent with no UI: mapping it is invisible.
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

                // No target size: the fullscreen view renders 1:1, so
                // the grab comes out at source pixels exactly.
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

        // No syncId on purpose: every shot keeps its own toast,
        // newest on top, instead of replacing the previous one.
        Services.Notifs.notify({
            app: "screenshot",
            summary: "Screenshot",
            body: file.split("/").pop(),
            icon: file,
            filepath: file,
            timeout: 10000,
            actions: [
                {
                    identifier: "default",
                    text: "Open"
                },
                {
                    identifier: "path",
                    text: "Copy path"
                }
            ]
        });
    }

    Process {
        id: copyProc

        property string file: ""

        command: ["sh", "-c", "wl-copy -t image/png < \"$1\"", "qs", copyProc.file]
    }

    // Fullscreen region picker: a frozen still underneath, drag a
    // rect on top. Coordinates stay in overlay (logical) pixels end
    // to end, so output scale can't skew the crop.
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

        // Overlay like the toast stack; the toast layer carries an
        // explicit order rule (see hyprland.lua) so toasts always
        // render above the picker instead of under it.
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-screenshot-picker"

        // Exclusive keyboard for Esc: a PanelWindow takes no
        // keyboard focus by default, and the focus grab below can
        // lose the race with the capture window mapping in the
        // same frame. This grants focus deterministically on map.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        property bool stillReady: false
        property string pickMode: "area"
        property rect winRect: Qt.rect(0, 0, 0, 0)
        property real startX: 0
        property real startY: 0
        property rect selection: Qt.rect(0, 0, 0, 0)
        property bool selecting: false

        onStillReadyChanged: {
            // Window mode skips dragging: the probed rect is already
            // monitor-relative logical pixels, so crop it directly.
            if (stillReady && pickMode === "window") {
                const w = picker.winRect;
                const k = root.lastScale;

                console.log("SHOTDBG: winRect=" + w.x + "," + w.y + " " + w.width + "x" + w.height + " k=" + k + " picker=" + picker.width + "x" + picker.height);
                picker.selection = Qt.rect(w.x, w.y, w.width, w.height);
                picker.acceptSelection();
            }
        }

        onVisibleChanged: {
            if (visible) {
                // Freeze through the capture window: same proven
                // chain as full mode, no per-view sizing surprises.
                // Toasts stay visible above the picker via the order
                // rule, so nothing is suspended or queued here.
                root.freezeStill();
            } else {
                focusGrab.active = false;
                stillReady = false;
                selection = Qt.rect(0, 0, 0, 0);
                selecting = false;
                still.source = "";
            }
        }

        // Keyboard focus for Esc: never bind active to visible,
        // asserting it in the show frame leaves the grab dead.
        HyprlandFocusGrab {
            id: focusGrab

            windows: [picker]

            onCleared: picker.close()
        }

        Timer {
            id: grabTimer

            interval: 100
            running: picker.visible
            repeat: false

            onTriggered: focusGrab.active = true
        }

        function overlayRect(): rect {
            const s = picker.selection;
            const x = Math.min(s.x, s.x + s.width);
            const y = Math.min(s.y, s.y + s.height);

            return Qt.rect(x, y, Math.abs(s.width), Math.abs(s.height));
        }

        function close(): void {
            // The frozen tmp frame stays: same path is overwritten on
            // the next capture and /tmp is cleaned on reboot. (rm-ing
            // here would race the clipboard copy of a just-finished
            // area shot.)
            picker.visible = false;
        }

        // The frozen frame. Shown once the capture window has
        // saved it; selection and crops run against these pixels.
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

        function acceptSelection(): void {
            let r = picker.overlayRect();

            // Clamp to the picker: window rects may stick out past
            // the screen (or round outside it on fractional scales).
            const x1 = Math.max(0, Math.min(r.x, picker.width));
            const y1 = Math.max(0, Math.min(r.y, picker.height));
            const x2 = Math.max(0, Math.min(r.x + r.width, picker.width));
            const y2 = Math.max(0, Math.min(r.y + r.height, picker.height));

            r = Qt.rect(x1, y1, Math.max(0, x2 - x1), Math.max(0, y2 - y1));

            console.log("SHOTDBG: accept sel=" + r.x + "," + r.y + " " + r.width + "x" + r.height + " imgStatus=" + cropImg.status);

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

        // Selection outline.
        Rectangle {
            x: picker.overlayRect().x
            y: picker.overlayRect().y
            width: picker.overlayRect().width
            height: picker.overlayRect().height
            visible: picker.selecting || (picker.stillReady && picker.overlayRect().width > 0)
            color: "transparent"
            border.width: 1
            border.color: Palette.accent
        }

        // Region-sized view onto the frozen still, grabbed as the
        // final file. Rendered at device pixels, so the crop keeps
        // full output resolution.
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
                const r = picker.overlayRect();
                const k = root.lastScale;

                cropBox.grabToImage(result => {
                    cropBox.visible = false;

                    const ok = result.saveToFile(root.pendingFile);

                    // Close first so the picker is already gone when
                    // the shot's toast pops above it.
                    picker.close();

                    if (ok)
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
