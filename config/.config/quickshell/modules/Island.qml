import QtQuick
import QtQuick.Layouts
import "root:/"

// One of the bar's three bordered boxes - .modules-left, .modules-center and
// .modules-right.
//
// Draws no brackets itself; those come from the Group widgets inside it, so
// one Island can hold several bracketed groups on one shared background (the
// left box holds the utilities group, the bare workspace buttons, and the
// media group). See Group.qml.
Rectangle {
    id: root

    default property alias content: inner.data
    color: Theme.bg
    radius: Theme.radius
    border.width: Theme.borderWidth
    // waybar's @focused: theme green at 80% alpha, not border_active - using
    // the palette key directly gave a visibly different hue.
    border.color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.8)

    // Border width counts on both sides like CSS padding inside a border.
    // Nothing else needed: every bar item already carries Theme.itemPad, so
    // the first and last item sit half a gap in from the border on their own.
    implicitWidth: inner.implicitWidth + 2 * border.width
    implicitHeight: Theme.islandHeight

    RowLayout {
        id: inner
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.border.width
        // Modules carry their own padding, the way waybar's per-module
        // `padding: 0 10px` rules did; a gap here would double-count.
        spacing: 0
    }
}
