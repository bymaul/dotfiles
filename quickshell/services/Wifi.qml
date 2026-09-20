pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Single source for wifi device state + signal-tier mapping.
// Replaces bar.wifiDevice / bar.connectedWifi prop-drilling.
Singleton {
    id: wifi

    readonly property var device: (Networking.devices?.values ?? []).find(d => d && d.type === DeviceType.Wifi) ?? null
    readonly property var connected: (wifi.device?.networks?.values ?? []).find(n => n && n.connected) ?? null

    function signalTier(s: real): int {
        if (s >= Theme.sigHigh)
            return 3;
        if (s >= Theme.sigMed)
            return 2;
        if (s >= Theme.sigLow)
            return 1;
        return 0;
    }
    function signalGlyph(s: real): string {
        const t = wifi.signalTier(Number(s ?? 0) || 0);
        if (t >= 3)
            return "󰤨";
        if (t === 2)
            return "󰤥";
        if (t === 1)
            return "󰤢";
        return "󰤟";
    }
}
