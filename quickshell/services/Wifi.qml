pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: wifi

    readonly property var allWifiDevices: (Networking.devices?.values ?? []).filter(d => d && d.type === DeviceType.Wifi)
    readonly property var device: wifi.allWifiDevices.length > 0 ? wifi.allWifiDevices[0] : null
    readonly property var rawNetworks: wifi.device?.networks?.values ?? []
    readonly property var connected: wifi.rawNetworks.find(n => n && n.connected) ?? null
    readonly property var connecting: wifi.rawNetworks.find(n => n && !n.connected && (n.state === ConnectionState.Connecting || n.stateChanging)) ?? null
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled ?? true
    readonly property bool enabled: !!Networking.wifiEnabled
    readonly property bool scanning: wifi.device ? !!wifi.device.scannerEnabled : false
    property bool listActive: false
    property var _networksCache: null
    function snapshotNetworks(): void {
        wifi._networksCache = wifi.sortedNetworks;
    }
    readonly property var sortedNetworks: {
        if (!wifi.listActive && wifi._networksCache !== null)
            return wifi._networksCache;
        const nets = wifi.rawNetworks.slice();
        function rank(n) {
            if (!n)
                return 4;
            if (n.connected)
                return 0;
            if (n.state === ConnectionState.Connecting || n.stateChanging)
                return 1;
            if (n.known)
                return 2;
            return 3;
        }
        nets.sort((a, b) => {
            const r = rank(a) - rank(b);
            if (r !== 0)
                return r;
            const sa = Number(a?.signalStrength ?? 0) || 0;
            const sb = Number(b?.signalStrength ?? 0) || 0;
            if (sb !== sa)
                return sb - sa;
            const na = String(a?.name ?? "").toLowerCase();
            const nb = String(b?.name ?? "").toLowerCase();
            return na < nb ? -1 : na > nb ? 1 : 0;
        });
        return nets;
    }
    readonly property var wiredDevice: (Networking.devices?.values ?? []).find(d => d && d.type === DeviceType.Wired) ?? null
    readonly property bool wiredConnected: wifi.wiredDevice ? !!wifi.wiredDevice.connected : false

    function networkKey(n: var): string {
        if (!n)
            return "";
        const bssid = String(n.bssid ?? n.macAddress ?? "");
        if (bssid !== "")
            return bssid.toLowerCase();
        return String(n.name ?? "") + "\0" + String(n.security ?? "");
    }
    function findNetwork(ssid: string, bssid: string): var {
        if (bssid !== undefined && bssid !== null && String(bssid) !== "")
            return wifi.rawNetworks.find(n => n && String(n.bssid ?? n.macAddress ?? "").toLowerCase() === String(bssid).toLowerCase()) ?? null;
        if (!ssid)
            return null;
        return wifi.rawNetworks.find(n => n && n.name === ssid) ?? null;
    }
    function signalLevel(s: real): real {
        return Theme.clamp01(Number(s ?? 0) || 0);
    }

    function signalTier(s: real): int {
        const level = wifi.signalLevel(s);
        if (level >= Theme.sigHigh)
            return 3;
        if (level >= Theme.sigMed)
            return 2;
        if (level >= Theme.sigLow)
            return 1;
        return 0;
    }
    function signalGlyph(s: real): string {
        const t = wifi.signalTier(s);
        if (t >= 3)
            return "󰤨";
        if (t === 2)
            return "󰤥";
        if (t === 1)
            return "󰤢";
        return "󰤟";
    }
}
