import QtQuick
import Quickshell.Io

// waybar's custom/bluetooth, which already shelled out to this script on a 5s
// interval. Kept as-is: the script is the authority on what the glyph should
// be, and reimplementing bluetoothctl parsing in QML would be a rewrite with
// no upside.
BarText {
    id: root
    text: ""

    onLeft: () => manager.running = true

    Process {
        id: manager
        command: ["blueman-manager"]
    }

    Process {
        id: status
        command: [Quickshell.env("HOME") + "/.config/waybar/scripts/bluetooth_status.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.text = this.text.trim()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: status.running = true
    }
}
