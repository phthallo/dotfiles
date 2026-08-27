import QtQuick
import Quickshell
import Quickshell.Networking
import "root:/"
import "root:/popups"

// waybar's network module. It polled nmcli twice every five seconds - once
// for the device list, once for the signal strength - because waybar had no
// way to watch NetworkManager. Quickshell.Networking is the same daemon over
// the bus, so this now costs nothing until something actually changes.
//
// Clicking it drops down the wifi picker rather than launching `kitty -e
// nmtui`, which is what the waybar config had to do.
BarText {
    id: root

    leftPadding: 10
    rightPadding: 10

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

    text: kind === "wifi"
            ? wifiIcons[Math.min(4, Math.floor(activeAp.signalStrength / 25))]
        : kind === "ethernet" ? "󰈀 LAN"
        : "󰖪"
    color: kind === "disconnected" ? Theme.fgDim : Theme.fg

    onLeft: () => popup.visible = !popup.visible

    NetworkPopup {
        id: popup
        // Anchored to the icon itself rather than to a hand-computed
        // offset in the bar window: mapToItem is not a binding, so a
        // position worked out once never moves again when the module
        // beside it changes width.
        anchor.item: root
    }
}
