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
    property int leftPad: 10
    property int rightPad: 10

    color: Theme.bg
    radius: Theme.radius
    border.width: Theme.borderWidth
    border.color: Theme.borderActive

    implicitWidth: inner.implicitWidth + leftPad + rightPad
    implicitHeight: Theme.islandHeight

    RowLayout {
        id: inner
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.leftPad
        // Modules carry their own padding, the way waybar's per-module
        // `padding: 0 10px` rules did; a gap here would double-count.
        spacing: 0
    }
}
