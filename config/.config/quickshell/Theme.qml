pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The palette, read straight from theme-switcher rather than generated into QML.
//
// Every other consumer on this desktop (wofi, swaync, kitty, starship...) gets
// a file rendered for it by apply-theme.sh from a .tpl. That indirection exists
// because those programs read static stylesheets and have to be SIGHUP'd or
// restarted to pick up a change. QML does not have that problem: FileView with
// watchChanges re-reads on write and every binding downstream updates itself.
//
// So this reads the theme's colors.json directly. apply-theme.sh needs no
// quickshell target at all, there is no generated file to gitignore, and a
// theme switch recolours the bar in the same frame it recolours everything
// else - no restart, no flash.
Singleton {
    id: root

    readonly property string base: Quickshell.env("HOME") + "/.config/theme-switcher"

    // Which theme is active. apply-theme.sh rewrites this file on every switch,
    // which is what makes the whole chain reactive: this reloads, themeName
    // changes, the colours FileView's path changes, and it reloads in turn.
    FileView {
        path: root.base + "/current-theme.json"
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: current
            property string theme: "gruvbox"
            property string wallpaper: ""
        }
    }

    readonly property string themeName: current.theme || "gruvbox"
    readonly property string wallpaper: current.wallpaper
        ? root.base + "/themes/" + root.themeName + "/" + current.wallpaper
        : ""

    FileView {
        path: root.base + "/themes/" + root.themeName + "/colors.json"
        watchChanges: true
        onFileChanged: reload()
        // Defaults are gruvbox, so a missing or half-written colors.json
        // degrades to a readable bar instead of a black-on-black one. A theme
        // switch rewrites this file, and there is a window where a partial
        // read is possible.
        JsonAdapter {
            id: c
            property string bg: "#282828"
            property string bg_alt: "#3c3836"
            property string surface: "#3c3836"
            property string surface2: "#504945"
            property string fg: "#ebdbb2"
            property string fg_dim: "#bdae93"
            property string accent: "#d79921"
            property string accent_alt: "#83a598"
            property string red: "#fb4934"
            property string orange: "#fe8019"
            property string yellow: "#fabd2f"
            property string green: "#b8bb26"
            property string teal: "#8ec07c"
            property string blue: "#83a598"
            property string mauve: "#d3869b"
            property string border_active: "#d79921"
            property string border_inactive: "#504945"
            property string overlay: "#665c54"
            property string shadow: "#1d2021"
        }
    }

    readonly property color bg: c.bg
    readonly property color bgAlt: c.bg_alt
    readonly property color surface: c.surface
    readonly property color surface2: c.surface2
    readonly property color fg: c.fg
    readonly property color fgDim: c.fg_dim
    readonly property color accent: c.accent
    readonly property color accentAlt: c.accent_alt
    readonly property color red: c.red
    readonly property color orange: c.orange
    readonly property color yellow: c.yellow
    readonly property color green: c.green
    readonly property color teal: c.teal
    readonly property color blue: c.blue
    readonly property color mauve: c.mauve
    readonly property color borderActive: c.border_active
    readonly property color borderInactive: c.border_inactive
    readonly property color overlay: c.overlay
    readonly property color shadow: c.shadow

    // The numbers waybar's stylesheet hardcoded, kept in one place so the
    // islands, the notification popups and the launcher stay on one rhythm.
    // 20 is gaps_out in hyprland.conf - the shell sits off each edge by the
    // same amount a tiled window does.
    readonly property int gap: 20
    readonly property int radius: 7
    readonly property int borderWidth: 2
    readonly property int barHeight: 50
    // The islands sit inside barHeight, below the top gap - waybar's
    // height:50 was the whole strip, not the height of a group.
    readonly property int islandHeight: barHeight - gap
    readonly property string fontFamily: "0xProto Nerd Font"
    readonly property int fontSize: 15
}
