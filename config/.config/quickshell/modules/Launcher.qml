import Quickshell.Io

// waybar's custom/arch: the distro glyph, opening vicinae.
BarText {
    text: ""
    onLeft: () => proc.running = true

    Process {
        id: proc
        command: ["vicinae", "open"]
    }
}
