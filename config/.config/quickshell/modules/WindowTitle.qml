import QtQuick
import Quickshell.Wayland
import "root:/"

// waybar's hyprland/window, capped at 20 characters. The cap is what keeps the
// centre island from shoving the left and right ones around as you switch
// between a shell and a browser tab with a long title.
//
// ToplevelManager rather than Hyprland.activeToplevel: it speaks the
// wlr-foreign-toplevel protocol, so it is populated from the moment the shell
// connects and needs no explicit refresh. Hyprland's own list starts empty and
// only fills on request, which left this blank on a quiet desktop.
BarText {
    readonly property string title: ToplevelManager.activeToplevel?.title ?? ""

    text: title.length > 20 ? title.slice(0, 20) + "…" : title
    color: Theme.fg
}
