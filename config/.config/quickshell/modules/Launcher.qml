import Quickshell.Io

// waybar's custom/arch: the distro glyph, opening vicinae.
BarText {
    // #custom-arch: padding-left 5, padding-right 10
    text: "\uF30A"   // arch
    onLeft: () => proc.running = true

    Process {
        id: proc
        command: ["vicinae", "open"]
    }
}
