import QtQuick
import Quickshell

// waybar's clock: 12-hour, zero-padded, no seconds and no AM/PM marker
// ({:%I:%M}) - so it only needs to tick once a minute rather than once a
// second.
//
// Qt's "hh" is 24-hour unless the format also contains AP, and adding AP means
// stripping the marker back off afterwards. Doing the arithmetic is shorter
// and says what it means.
BarText {
    id: root

    readonly property int hour12: clock.hours % 12 || 12
    text: String(hour12).padStart(2, "0") + ":" + String(clock.minutes).padStart(2, "0")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
