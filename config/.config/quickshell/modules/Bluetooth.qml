import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "root:/"
import "root:/popups"

// waybar's custom/bluetooth: BlueZ publishes adapter state on the bus, so
// this follows it directly instead of polling bluetoothctl every 5s. Clicking
// opens the device list instead of blueman-manager.
BarText {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool anyConnected: {
        if (!adapter) return false;
        for (const d of adapter.devices.values)
            if (d.connected) return true;
        return false;
    }

    text: !adapter || !adapter.enabled ? "󰂲"
        : anyConnected ? "󰂱" : "󰂯"
    color: adapter?.enabled ? Theme.fg : Theme.fgDim

    onLeft: () => popup.open = !popup.open

    BluetoothPopup {
        id: popup
        // Anchored to the icon itself, not a computed offset - mapToItem
        // isn't a binding, so a fixed offset wouldn't track the module
        // resizing.
        anchor.item: root
    }
}
