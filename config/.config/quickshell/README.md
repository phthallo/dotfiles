# quickshell config

Replaces waybar, swaync, nwg-dock-hyprland and (for the wifi/bluetooth
pickers) `kitty -e nmtui` / `blueman`, in one process.

    qs -p ~/dotfiles/config/.config/quickshell

## Handover

Three things cannot run at the same time as this:

- **waybar** and **nwg-dock-hyprland** - both would draw the same thing twice.
- **swaync** - only one process on the session may own
  `org.freedesktop.Notifications`. swaync's unit is `Type=dbus`, so
  `systemctl --user stop swaync` is not enough: the next client re-activates
  it. Mask it, or remove it from `hyprland.conf`'s autostart.

`swaync-client`'s replacement is IPC:

    qs -p <this dir> ipc call notifications toggle   # open/close the panel
    qs -p <this dir> ipc call notifications dnd      # do not disturb
    qs -p <this dir> ipc call notifications clear

Notification history is **not** persisted across a reload; swaync's was.

## Where the CPU went

The old setup woke up constantly. Every wake is a timer firing, a process
forking, a pipe being read and a label being relaid out - on battery that is
the difference between a shell you never notice and one that shows up in
`powertop`.

Measured on this machine, idle desktop, 60s windows, `utime+stime` from
`/proc/<pid>/stat`:

    waybar + swaync + nwg-dock   307 jiffies / 60s   ~5.1% of one core
    quickshell                    28 jiffies / 60s   ~0.5% of one core

What was polling, and what it is now:

| was | every | now |
| --- | --- | --- |
| waybar `mpris` | 1s, polling the player | `Services.Mpris`, dbus signals |
| waybar `cpu` + `memory` | 2s, forking | one 2s timer reading `/proc` through `FileView`, no fork |
| `custom/bluetooth` -> `bluetooth_status.sh` -> `bluetoothctl` | 5s, forking | `Quickshell.Bluetooth`, bluez over the bus |
| swaync's toggles shelling out to `wpctl`/`nmcli`/`bluetoothctl` | every panel open | Pipewire/Networking/Bluetooth properties |
| an earlier draft of this config polling `nmcli` twice | 5s, forking | `Quickshell.Networking`, NetworkManager over the bus |
| nwg-dock-hyprland | a second process with its own hyprland connection | `ToplevelManager`, wlr-foreign-toplevel events, in-process |

waybar's `network` and `battery` were already event-driven (netlink and
UPower) and stay that way here; the clock ticks once a minute either way,
since the format has no seconds in it.

What is left running when the desktop is idle: one 2s timer per SysInfo
module (cpu and memory), a clock that ticks once a minute, and event
subscriptions that cost nothing until something changes. No forks.

The rest is about not doing work while nothing is on screen:

1. **Wifi scanning and bluetooth discovery are tied to popup visibility.**
   `scannerEnabled`/`discovering` go true when the popup opens and false when
   it closes - a radio scanning in the background is a battery cost with
   nothing to show for it.
2. **Backlight is read once per panel open.** It is the one control with no
   bus to listen to, so it gets a `Process`; on a timer that would be a fork
   every few seconds for a number nobody is looking at.
3. **The dock hides and drops its exclusive zone when nothing is running**,
   and its delegates come from a `ScriptModel`, which diffs by identity - so
   opening a window somewhere else does not rebuild every button and reload
   every icon.
4. **Toasts stop when the control center opens**, and when DND goes on:
   whatever would have popped up is already in the list behind it.
5. **The control center and the toasts exist once, on the focused monitor**,
   rather than once per screen. The bar and the dock are still per-monitor,
   because that is where they belong.
6. **Animations are all one-shot `Behavior`s.** waybar's critical-battery
   blink is deliberately not carried over - an animation that never stops
   keeps the compositor compositing all day.

Held notifications are capped at 100; each one holds an image buffer, and an
app stuck in a loop should not be able to grow the shell until it swaps.
