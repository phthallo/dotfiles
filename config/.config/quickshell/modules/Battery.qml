import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower

// waybar's battery module. The icon ramp and the warning/critical thresholds
// are carried over verbatim (30% and 15%), as is the click target - the logout
// menu, which is an odd place to hang it but is where muscle memory now is.
BarText {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property int percent: dev ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: dev
        ? dev.state === UPowerDeviceState.Charging
          || dev.state === UPowerDeviceState.PendingCharge
        : false

    readonly property var icons: ["", "", "", "", ""]

    text: (charging ? "" : icons[Math.min(4, Math.floor(percent / 20))])
        + " " + percent + "%"

    // waybar drove these off .warning/.critical CSS classes; the colours are
    // the theme's own rather than the stylesheet's hardcoded gruvbox.
    color: percent <= 15 && !charging ? Theme.red
         : percent <= 30 && !charging ? Theme.yellow
         : Theme.fg

    onLeft: () => logout.running = true

    Process {
        id: logout
        command: ["wleave", "-l", Quickshell.env("HOME") + "/.config/wlogout/layout",
                  "-b", "5", "-T", "40%", "-B", "40%", "-L", "5%", "-R", "5%"]
    }
}
