import QtQuick
import QtQuick.Layouts
import "root:/"

// One of the bar's three bordered boxes - .modules-left, .modules-center and
// .modules-right.
//
// The box does NOT draw brackets. waybar's "[" and "]" come from the group/*
// widgets INSIDE the container, so one box can hold several bracketed groups:
// the left box wraps the utilities group, the bare workspace buttons and the
// media group all on one background, which is why workspaces and mpris sit on
// the dark surface rather than on the wallpaper. See Group.qml.
Rectangle {
    id: root

    default property alias content: inner.data
    // Zero by default: every item in the bar carries Theme.itemPad on
    // both its sides, so the first and last already sit half a gap in
    // from the border without the island adding more.
    property int leftPad: 0
    property int rightPad: 0

    color: Theme.bg
    radius: Theme.radius
    border.width: Theme.borderWidth
    // waybar's @focused is rgba(184,187,38,0.8) - the theme green at 80%
    // alpha over the wallpaper, not border_active. Reading the palette key
    // instead gave a visibly different hue.
    border.color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.8)

    // CSS padding sits inside the border, so the border's own 2px counts on
    // both sides; without it every label sat 2px left of waybar's.
    implicitWidth: inner.implicitWidth + leftPad + rightPad + 2 * border.width
    implicitHeight: Theme.islandHeight

    RowLayout {
        id: inner
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.leftPad + root.border.width
        // Modules carry their own padding, the way waybar's per-module
        // `padding: 0 10px` rules did; a gap here would double-count.
        spacing: 0
    }
}
