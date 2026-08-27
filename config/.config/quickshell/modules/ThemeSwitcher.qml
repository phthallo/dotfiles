import Quickshell
import Quickshell.Io
import "root:/popups"

// waybar's custom/themeswitcher.
//
// Left click opens the picker in-process rather than spawning wofi through
// theme-switcher.sh: no cold start, and an xdg popup dismisses itself on an
// outside click, which wofi as a layer surface could only fake. Right and
// middle click still go through the scripts, which are what a keybind or a
// terminal uses and where apply-theme.sh does the actual restyling.
BarText {
    // #custom-themeswitcher: padding-left 5, padding-right 10
    leftPadding: 5
    rightPadding: 10
    id: root
    text: "\uE22B"   // palette

    property string script: Quickshell.env("HOME") + "/.config/waybar/scripts/theme-switcher.sh"
    property string cycler: Quickshell.env("HOME") + "/.config/waybar/scripts/wallpaper-cycler.sh"

    onLeft: () => popup.visible = !popup.visible
    onRight: () => run([root.script, "random"])
    onMiddle: () => run([root.cycler, "next"])

    function run(argv) {
        proc.command = argv;
        proc.running = true;
    }

    Process {
        id: proc
    }

    ThemePopup {
        id: popup
        anchor.item: root
    }
}
