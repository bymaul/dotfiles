import QtQuick
import Quickshell.Bluetooth
import "../components"
import "../services" as Services
BarIcon {
    required property var bar
    glyph: {
      if (!Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.enabled)
        return "󰂲";
      const vals = Bluetooth.devices ? Bluetooth.devices.values : [];
      for (let i = 0; i < vals.length; i++) {
        const d = vals[i];
        if (d && (d.connected || d.state === BluetoothDeviceState.Connected))
          return "󰂱";
      }
      return "󰂯";
    }
    glyphColor: Bluetooth.defaultAdapter?.enabled ? Services.Theme.fg : Services.Theme.dim
    tipText: {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter)
            return "No Bluetooth adapter";
        if (!adapter.enabled)
            return "Bluetooth off";
        const vals = Bluetooth.devices ? Bluetooth.devices.values : [];
        for (let i = 0; i < vals.length; i++) {
            const d = vals[i];
            if (d && (d.connected || d.state === BluetoothDeviceState.Connected))
                return "Connected: " + (d.name || d.deviceName || d.address);
        }
        let paired = 0;
        for (let i = 0; i < vals.length; i++) {
            if (vals[i] && (vals[i].paired || vals[i].bonded))
                paired++;
        }
        if (paired > 0)
            return paired === 1 ? "1 paired · not connected" : paired + " paired · not connected";
        return "On · not connected";
    }
    tipAnchor: bar
    onClicked: bar.toggleBluetooth()
}
