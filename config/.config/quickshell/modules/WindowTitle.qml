import QtQuick
import Quickshell.Wayland
import "root:/"

// waybar's hyprland/window, capped at 20 characters so the centre island
// doesn't shove the side ones around on a long title.
//
// ToplevelManager rather than Hyprland.activeToplevel: it speaks
// wlr-foreign-toplevel and is populated from the moment the shell connects.
// Hyprland's own list starts empty until explicitly refreshed, which left
// this blank on a quiet desktop.
BarText {
    readonly property string title: ToplevelManager.activeToplevel?.title ?? ""

    text: title.length > 20 ? title.slice(0, 20) + "…" : title
    color: Theme.fg
}
