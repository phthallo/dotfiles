pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The palette, read straight from theme-switcher's colors.json. FileView with
// watchChanges re-reads on write, so unlike wofi/swaync/kitty/starship (which
// need a rendered file and a restart), a theme switch recolours everything
// here in the same frame.
Singleton {
    id: root

    readonly property string base: Quickshell.env("HOME") + "/.config/theme-switcher"

    // apply-theme.sh rewrites this on every switch; it reloads, themeName
    // changes, and the colours FileView's path changes and reloads in turn.
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
        // (there's a window mid-switch where that's possible) degrades to a
        // readable bar instead of black-on-black.
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

    // waybar's hardcoded numbers, kept in one place. gap matches gaps_out in
    // hyprland.conf.
    readonly property int gap: 20
    readonly property int radius: 7
    readonly property int borderWidth: 2
    readonly property int barHeight: 50
    readonly property int islandHeight: barHeight - gap
    // Loaded by path rather than family name: Qt resolves "0xProto Nerd Font"
    // to the Propo cut (1.0-1.15em icon advance, ~6px wider than waybar's
    // Pango-rendered bar). The Mono cut has the right advance but halves icon
    // ink. This loads the base cut directly.
    property FontLoader nerdFont: FontLoader {
        source: "file:///usr/share/fonts/0xProto/0xProtoNerdFont-Regular.ttf"
    }
    readonly property string fontFamily: nerdFont.status === FontLoader.Ready
        ? nerdFont.name : "0xProto Nerd Font"
    readonly property int fontSize: 15
    // 0xProto advances 0.62em (9.3px at this size); Pango floors to 9, Qt
    // rounds to 10. This keeps the bar from drifting a pixel wider per
    // character than waybar's.
    readonly property real letterSpacing: -1

    // Clear space either side of an item's ink (not its font advance) - every
    // module, separator and group bracket. Neighbours end up twice this
    // apart. waybar's per-module padding ran 0/5/10px inconsistently; this is
    // a deliberate, uniform departure from that.
    readonly property int itemPad: 10

    // Chrome rhythm, copied from templates/shared/chrome.css.tpl.
    readonly property int panelWidth: 420
    // Panels round like a hyprland window, not like the bar islands - they
    // float over the desktop at gaps_out, read against windows beside them.
    readonly property int panelRadius: 10
    readonly property int pillRadius: 999
    readonly property int panelPad: 16
    readonly property int blockGap: 14
    readonly property int cardGap: 4
    readonly property int panelFontSize: 15

    // Shared open animation for every dropped-down surface. Closing is
    // instant - the compositor tears a grabbing popup down the moment the
    // click lands outside, leaving no room for an outro.
    readonly property int openDuration: 140
    readonly property int openSlide: 8

    // shade(@cc_bg, 1.08) / 1.10 from the swaync stylesheet.
    function shade(c, f) {
        return Qt.rgba(Math.min(1, c.r * f), Math.min(1, c.g * f),
                       Math.min(1, c.b * f), c.a);
    }
    readonly property color card: shade(bg, 1.08)
    readonly property color raised: shade(bg, 1.10)
    readonly property color raisedHover: shade(bg, 1.35)
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.10)
}
