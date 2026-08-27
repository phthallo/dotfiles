import QtQuick
import Quickshell
import Quickshell.Networking
import "root:/"
import "root:/popups"

// waybar's network module. Reads NetworkManager over the bus via
// Quickshell.Networking instead of polling nmcli every 5s, so it costs
// nothing until something actually changes. Click drops down the wifi picker
// instead of launching `kitty -e nmtui`.
BarText {
    id: root

    readonly property var wired: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wired && d.connected) return d;
        return null;
    }

    readonly property var wifi: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi) return d;
        return null;
    }

    readonly property var activeAp: {
        if (!wifi || !wifi.connected) return null;
        for (const n of wifi.networks.values)
            if (n.connected) return n;
        return null;
    }

    // Ethernet wins if both are up: it is the one actually carrying traffic
    // when a dock is plugged in.
    readonly property string kind: wired ? "ethernet"
        : activeAp ? "wifi" : "disconnected"

    readonly property var wifiIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    // Checks activeAp directly rather than going through kind: kind and
    // activeAp are separate bindings, and a rescan can settle them a beat
    // apart. Reading kind === "wifi" here would risk a null activeAp
    // dereference mid-cascade, which throws and freezes this binding at its
    // last value instead of updating.
    // signalStrength is a 0.0-1.0 fraction, not NetworkManager's raw 0-100
    // Strength byte - dividing by 25 pinned every network to the outline icon.
    text: wired ? "󰈀 LAN"
        : activeAp ? wifiIcons[Math.min(4, Math.floor(activeAp.signalStrength * 4))]
        : "󰖪"
    color: kind === "disconnected" ? Theme.fgDim : Theme.fg

    onLeft: () => popup.open = !popup.open

    NetworkPopup {
        id: popup
        // Anchored to the icon itself, not a computed offset - mapToItem
        // isn't a binding, so a fixed offset wouldn't track the module
        // resizing.
        anchorItem: root
    }
}
