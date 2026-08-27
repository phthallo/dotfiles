import QtQuick
import Quickshell

// waybar's clock: 12-hour, zero-padded, no seconds, no AM/PM ({:%I:%M}) - only
// needs to tick once a minute.
//
// Qt's "hh" format is 24-hour unless AP is also in the string, which then has
// to be stripped back off. Doing the arithmetic directly is shorter.
BarText {
    id: root

    readonly property int hour12: clock.hours % 12 || 12
    text: String(hour12).padStart(2, "0") + ":" + String(clock.minutes).padStart(2, "0")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
