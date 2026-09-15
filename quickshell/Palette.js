const barBg = "#CC141415";
const bg = "#141415";
const surface = "#1c1c24";
const hoverBg = "#252530";
const activeBg = "#252530";
const border = "#26CDCDCD";
const fg = "#cdcdcd";
const dim = "#878787";
const accent = "#aeaed1";
const onAccent = "#141415";
const white = "#ffffff";
const warn = "#f3be7c";
const danger = "#d8647e";
const font = "JetBrainsMono Nerd Font Propo";
const px10 = 10;
const px11 = 11;
const px12 = 12;
const px13 = 13;
const px14 = 14;
const popupWidth = 340;
const settingsWidth = 400;
const launcherWidth = 480;
const popupMargin = 10;
const popupTopGap = 6;
const popupPadding = 8;
const popupSpacing = 8;
const rowHeight = 36;
const listRowHeight = 40;
const toastWidth = 300;
const barHeight = 34;
const groupSpacing = 12;
const listSpacing = 4;
const listVisible = 10;
const tileHeight = 40;
const grabDelay = 100;
const focusDelay = grabDelay + 50;
const scanTimeout = 15000;
const toastTimeout = 5000;
const osdTimeout = 1500;
const toastMax = 5;
const historyMax = 30;
const volumeMax = 1.5;
const volumeStep = 0.05;
const brightnessStep = 5;
const brightnessMin = 5;
const sigHigh = 0.75;
const sigMed = 0.5;
const sigLow = 0.25;
function clamp(x, a, b) {
    return Math.max(a, Math.min(b, x));
}
function clamp01(x) {
    return Math.max(0, Math.min(1, x));
}
function listHeight(rows) {
    return rows * rowHeight + Math.max(0, rows - 1) * listSpacing;
}
