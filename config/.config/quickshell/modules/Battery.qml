import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "root:/"

// waybar's battery module. The icon ramp and the warning/critical thresholds
// carry over verbatim (30% and 15%), as does the click target - the logout
// menu, which is an odd place to hang it but is where muscle memory is.
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

    readonly property var icons: ["\uF244", "\uF243", "\uF242", "\uF241", "\uF240"]

    text: (charging ? "\uF5E7"
         : plugged ? "\uF1E6 "
         : icons[Math.min(4, Math.floor(percent / 20))])
        + " " + percent + "%"

    // #battery.charging and .plugged filled the cell green with the bar
    // background as ink; .critical:not(.charging) filled it red. waybar also
    // blinked the critical state, which is left out deliberately - an
    // animation that never stops is not something to put on a bar you look at
    // all day.
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
