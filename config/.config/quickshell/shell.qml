import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "modules"

// Entry point. `qs` loads this file and nothing else - everything below is
// reached from here.
//
// Porting notes and the waybar/swaync/nwg-dock handover live in README.md
// next to this file; the short version is that this cannot share a session
// with waybar or nwg-dock (both would draw the same thing twice) or with
// swaync (only one process can own the notification bus name).
ShellRoot {
    id: root

    // One of each per monitor, created and destroyed as monitors come and go.
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        Dock {}
    }

    // Toasts and the control center are one per session, not one per monitor:
    // swaync put them on the focused output, and duplicating them means two
    // panels opening at once and two copies of every toast to dismiss.
    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name;
        for (const screen of Quickshell.screens)
            if (screen.name === name)
                return screen;
        return Quickshell.screens[0] ?? null;
    }

    NotificationPopups { modelData: root.focusedScreen }

    ControlCenter { modelData: root.focusedScreen }

    // swaync-client's job: something for a keybind (or a test run) to talk to.
    //     qs -p ~/dotfiles/config/.config/quickshell ipc call notifications toggle
    IpcHandler {
        target: "notifications"

        function toggle(): void {
            Notifications.panelOpen = !Notifications.panelOpen;
        }
        function open(): void { Notifications.panelOpen = true; }
        function close(): void { Notifications.panelOpen = false; }
        function dnd(): void { Notifications.dnd = !Notifications.dnd; }
        function clear(): void { Notifications.dismissAll(); }
        function count(): int { return Notifications.list.length; }
    }
}
