import Quickshell.Wayland
import "root:/"

// waybar's idle_inhibitor: eye open means idling is allowed, crossed out means
// it's held off. Attached to the bar's own surface, which is always mapped,
// so the inhibit lasts exactly as long as it's toggled on.
BarText {
    // #idle_inhibitor: padding 0 10px 0 0
    id: root

    required property var window

    text: inhibitor.enabled ? "\uF06E" : "\uF070"   // eye / eye-slash
    color: inhibitor.enabled ? Theme.accent : Theme.fg
    onLeft: () => inhibitor.enabled = !inhibitor.enabled

    IdleInhibitor {
        id: inhibitor
        window: root.window
        enabled: false
    }
}
