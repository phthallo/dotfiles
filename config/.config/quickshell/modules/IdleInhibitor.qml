import Quickshell.Wayland

// waybar's idle_inhibitor: eye open means idling is allowed, eye crossed out
// means it is being held off.
//
// waybar spoke the idle-inhibit protocol itself. Quickshell exposes the same
// thing per-window, so the inhibitor is attached to the bar's own surface -
// the bar is always mapped, so the inhibit lasts exactly as long as it is
// toggled on.
BarText {
    id: root

    required property var window

    text: inhibitor.enabled ? "" : ""
    color: inhibitor.enabled ? Theme.accent : Theme.fg
    onLeft: () => inhibitor.enabled = !inhibitor.enabled

    IdleInhibitor {
        id: inhibitor
        window: root.window
        enabled: false
    }
}
