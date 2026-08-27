import QtQuick
import Quickshell

// waybar's clock: 12-hour, zero-padded, no seconds - so it only needs to tick
// once a minute rather than once a second.
BarText {
    id: root
    text: Qt.formatDateTime(clock.date, "hh:mm")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
