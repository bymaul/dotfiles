pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string barBg: "#D9141415"
    property string bg: "#141415"
    property string surface: "#1c1c24"
    property string hoverBg: "#252530"
    property string activeBg: "#252530"
    property string border: "#26CDCDCD"
    property string fg: "#cdcdcd"
    property string dim: "#878787"
    property string accent: "#aeaed1"
    property string accentFg: "#141415"
    property string white: "#ffffff"
    property string transparent: "transparent"
    property string warn: "#f3be7c"
    property string danger: "#d8647e"
    property string font: "JetBrainsMono Nerd Font Propo"

    property int px10: 10
    property int px11: 11
    property int px12: 12
    property int px13: 13
    property int px14: 14

    property int popupWidth: 340
    property int settingsWidth: 400
    property int launcherWidth: 480
    property int barMargin: 8
    property int popupMargin: 6
    property int popupTopGap: 6
    property int popupPadding: 8
    property int popupSpacing: 8
    property int rowHeight: 36
    property int listRowHeight: 40
    property int toastWidth: 300
    property int osdWidth: 150
    property int osdBottomMargin: 32
    property int barHeight: 34
    property int groupSpacing: 12
    property int listSpacing: 4
    property int listVisible: 7
    property int resultMax: 40
    property int tileHeight: 40

    property int grabDelay: 100
    property int focusDelay: root.grabDelay + 50
    property int refilterDelay: 90
    property int scanTimeout: 15000
    property int toastTimeout: 5000
    property int osdTimeout: 1500
    property int toastStickyTimeout: 30000
    property int toastMax: 5
    property int historyMax: 20

    property real volumeMax: 1.5
    property real volumeStep: 0.05
    property int brightnessStep: 5
    property int brightnessMin: 5

    property real sigHigh: 0.75
    property real sigMed: 0.5
    property real sigLow: 0.25

    function clamp(x, a, b): real {
        return Math.max(a, Math.min(b, x));
    }
    function clamp01(x): real {
        return Math.max(0, Math.min(1, x));
    }
    function listHeight(rows): int {
        return rows * root.rowHeight + Math.max(0, rows - 1) * root.listSpacing;
    }
}
