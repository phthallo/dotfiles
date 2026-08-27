import QtQuick
import Quickshell
import "root:/"

// Shared chrome for the small panels the bar drops down: same surface, border
// and radius as the control center, so a wifi list and the notification panel
// read as the same window at different sizes.
//
// grabFocus makes this an xdg popup with a pointer grab, so a click anywhere
// outside dismisses it. That is the thing wofi could never do as a layer
// surface - a layer surface never sees the focus-out.
PopupWindow {
    id: root

    default property alias content: inner.data
    property int contentWidth: 320

    implicitWidth: contentWidth
    implicitHeight: Math.min(600, inner.implicitHeight + 2 * Theme.panelPad)
    color: "transparent"
    grabFocus: true

    // Anchor at the bottom edge of whatever item opened it and grow down
    // from there; SlideX keeps a popup opened near the screen edge on screen
    // instead of letting it hang off the side.
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.panelRadius
        border.width: Theme.borderWidth
        border.color: Theme.borderActive

        Column {
            id: inner
            anchors.fill: parent
            anchors.margins: Theme.panelPad
            spacing: Theme.cardGap
        }
    }
}
