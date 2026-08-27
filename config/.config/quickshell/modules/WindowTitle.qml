import Quickshell.Hyprland

// waybar's hyprland/window, capped at 20 characters. The cap is what keeps the
// centre island from shoving the left and right ones around as you switch
// between a shell and a browser tab with a long title.
BarText {
    readonly property string title: Hyprland.activeToplevel?.title ?? ""
    text: title.length > 20 ? title.slice(0, 20) + "…" : title
    color: Theme.fg
}
