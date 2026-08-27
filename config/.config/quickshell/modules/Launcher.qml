import Quickshell.Io

// waybar's custom/arch: the distro glyph, opening vicinae.
BarText {
    text: "\uF30A"   // arch
    onLeft: () => proc.running = true

    Process {
        id: proc
        command: ["vicinae", "open"]
    }
}
