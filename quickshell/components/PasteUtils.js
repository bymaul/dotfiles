function validAddress(addr) {
    return /^0x[0-9a-f]+$/i.test(String(addr ?? ""));
}

function parseFocusProbe(text) {
    const parts = String(text ?? "").trim().split("\t");
    const addr = parts[0] ?? "";
    return {
        address: validAddress(addr) ? addr : "",
        winClass: (parts[1] ?? "").toLowerCase()
    };
}

function isTerminal(winClass) {
    return /kitty|alacritty|foot|wezterm|ghostty|konsole|gnome-terminal|xfce4-terminal|terminator|tilix|xterm|rxvt|hyper|tabby|stterm|\bst\b/.test(String(winClass ?? ""));
}

function pasteMods(winClass) {
    return isTerminal(winClass) ? "CTRL, SHIFT" : "CTRL";
}
