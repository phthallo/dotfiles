import QtQuick
import Quickshell.Io
import "root:/"

// waybar's network module, which read the interface directly. Quickshell has
// no network service, so this polls nmcli - which is also what the click
// target (nmtui) talks to, so the two can never disagree about state.
BarText {
    id: root

    property string kind: "disconnected"   // wifi | ethernet | disconnected
    property int strength: 0

    readonly property var wifiIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    text: kind === "wifi" ? wifiIcons[Math.min(4, Math.floor(strength / 25))]
        : kind === "ethernet" ? "󰈀 LAN"
        : "󰖪"
    color: kind === "disconnected" ? Theme.fgDim : Theme.fg

    onLeft: () => nmtui.running = true

    Process {
        id: nmtui
        command: ["kitty", "-e", "nmtui"]
    }

    Process {
        id: poll
        // TYPE:STATE:SIGNAL for every device, terse and colon-separated so it
        // parses without caring about locale or column widths.
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let kind = "disconnected";
                for (const line of this.text.trim().split("\n")) {
                    const [type, state] = line.split(":");
                    if (state !== "connected")
                        continue;
                    // Ethernet wins if both are up: it is the one actually
                    // carrying traffic when a dock is plugged in.
                    if (type === "ethernet") {
                        kind = "ethernet";
                        break;
                    }
                    if (type === "wifi")
                        kind = "wifi";
                }
                root.kind = kind;
                if (kind === "wifi")
                    signalPoll.running = true;
            }
        }
    }

    Process {
        id: signalPoll
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL", "device", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                // ACTIVE is yes/no rather than IN-USE's "*" in a padded
                // column, so this does not depend on nmcli's formatting.
                const active = this.text.trim().split("\n").find(l => l.startsWith("yes:"));
                if (active)
                    root.strength = Number(active.split(":")[1]) || 0;
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }
}
