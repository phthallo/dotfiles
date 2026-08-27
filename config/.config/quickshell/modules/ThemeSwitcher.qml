import Quickshell.Io
import Quickshell

// waybar's custom/themeswitcher. Still shells out to theme-switcher.sh rather
// than reimplementing the picker in QML: the script is what apply-theme.sh and
// the wallpaper cycler are built around, and it stays the single entry point
// whether the click comes from here, a keybind or a terminal.
//
// The left-click picker is the one piece that will move in-process later -
// see Picker.qml - because that is the part quickshell can do better than
// wofi (no cold start, and it can dismiss on an outside click, which wofi
// as a layer surface cannot).
BarText {
    // #custom-themeswitcher: padding-left 5, padding-right 10
    leftPadding: 5
    rightPadding: 10
    id: root
    text: "\uE22B"   // palette

    property string script: Quickshell.env("HOME") + "/.config/waybar/scripts/theme-switcher.sh"
    property string cycler: Quickshell.env("HOME") + "/.config/waybar/scripts/wallpaper-cycler.sh"

    onLeft: () => run([root.script, "menu"])
    onRight: () => run([root.script, "random"])
    onMiddle: () => run([root.cycler, "next"])

    function run(argv) {
        proc.command = argv;
        proc.running = true;
    }

    Process {
        id: proc
    }
}
