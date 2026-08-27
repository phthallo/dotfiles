import Quickshell
import "modules"

// Entry point. `qs` loads this file and nothing else - everything below is
// reached from here.
//
// Porting notes and the swaync/waybar handover live in README.md next to this
// file; the short version is that this cannot share a session with waybar
// (both would draw a bar) or swaync (only one process can own the
// notification bus name).
ShellRoot {
    // One bar per monitor, created and destroyed as monitors come and go.
    Variants {
        model: Quickshell.screens
        Bar {}
    }
}
