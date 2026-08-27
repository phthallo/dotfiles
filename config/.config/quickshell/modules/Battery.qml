import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "root:/"

// waybar's battery module: same icon ramp and warning/critical thresholds
// (30%/15%), and clicking still opens the logout menu.
BarText {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property int percent: dev ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: dev
        ? dev.state === UPowerDeviceState.Charging
          || dev.state === UPowerDeviceState.PendingCharge
        : false
    readonly property bool plugged: dev
        ? dev.state === UPowerDeviceState.FullyCharged
        : false
    readonly property bool critical: percent <= 15 && !charging && !plugged

    readonly property var icons: ["", "", "", "", ""]

    text: (charging ? ""
         : plugged ? " "
         : icons[Math.min(4, Math.floor(percent / 20))])
        + " " + percent + "%"

    // No blink on critical, unlike waybar - not something worth animating
    // forever on a bar you look at all day.
    chipColor: charging || plugged ? Theme.green
             : critical ? Theme.red
             : "transparent"
    color: charging || plugged ? Theme.bg : Theme.fg

    topPadding: 4
    bottomPadding: 4

    onLeft: () => logout.running = true

    Process {
        id: logout
        command: ["wleave", "-l", Quickshell.env("HOME") + "/.config/wlogout/layout",
                  "-b", "5", "-T", "40%", "-B", "40%", "-L", "5%", "-R", "5%"]
    }
}
