import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "root:/"
import "root:/popups"

// waybar's custom/bluetooth, which ran a shell script every five seconds to
// ask bluetoothctl whether the adapter was powered. BlueZ publishes that on
// the bus, so the glyph now follows the adapter instead of trailing it by up
// to five seconds, and nothing is spawned to find out.
//
// Clicking it opens the device list rather than blueman-manager.
BarText {
    id: root

    leftPadding: 10
    rightPadding: 10

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

    onLeft: () => popup.visible = !popup.visible

    BluetoothPopup {
        id: popup
        // Anchored to the icon itself rather than to a hand-computed
        // offset in the bar window: mapToItem is not a binding, so a
        // position worked out once never moves again when the module
        // beside it changes width.
        anchor.item: root
    }
}
