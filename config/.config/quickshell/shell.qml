//@ pragma DropExpensiveFonts

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "modules"

// Entry point - `qs` loads this file and nothing else. Can't share a session
// with waybar or nwg-dock (would draw the same thing twice) or swaync (only
// one process can own the notification bus name). See README.md.
ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        Dock {}
    }

    // Toasts and the control center are one per session, not per monitor -
    // swaync put them on the focused output, and duplicating them means two
    // panels and two copies of every toast.
    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name;
        for (const screen of Quickshell.screens)
            if (screen.name === name)
                return screen;
        return Quickshell.screens[0] ?? null;
    }

    // Built on first use and torn down after, so future additions to either
    // tree cost nothing until something opens them.
    LazyLoader {
        active: Notifications.popups.length > 0
        NotificationPopups { modelData: root.focusedScreen }
    }

    LazyLoader {
        active: Notifications.panelOpen
        ControlCenter { modelData: root.focusedScreen }
    }

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
