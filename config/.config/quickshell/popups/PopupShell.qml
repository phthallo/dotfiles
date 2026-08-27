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

    // The window is bigger than the card it draws: transparent padding on
    // every side, with the card centred in it. SlideX only guarantees the
    // *window* stays on screen, so a popup hung off a bar item near the edge
    // used to end up with its border flush against the screen - and the
    // theme switcher lives in the left island, so it always did. Padding the
    // window means the card lands Theme.gap from the edge, the same offset
    // every tiled window and the bar itself use. The mask keeps the padding
    // from eating clicks: input outside the card passes through, so a click
    // beside it still dismisses through the grab.
    readonly property int pad: Theme.gap
    readonly property int dropGap: Math.round(Theme.gap / 2)

    // Callers flip `open`, never `visible`. The compositor closes a grabbing
    // popup on its own when a click lands outside it, so a `visible: open`
    // binding would go stale and the next click on the bar button would only
    // toggle the flag back - the classic two-clicks-to-reopen bug. Syncing
    // both directions instead keeps the button an honest toggle: clicking it
    // again is itself an outside click, the grab eats it, the surface goes,
    // and this sees that and clears the flag.
    property bool open: false
    onOpenChanged: if (visible !== open) visible = open
    onVisibleChanged: {
        if (open !== visible) open = visible;
        if (visible) show.restart();
    }

    implicitWidth: contentWidth + 2 * pad
    implicitHeight: dropGap + pad
        + Math.min(600, inner.implicitHeight + 2 * Theme.panelPad)
    mask: Region { item: card }
    color: "transparent"
    grabFocus: true

    // Anchor at the bottom edge of whatever item opened it and grow down
    // from there; SlideX keeps a popup opened near the screen edge on screen
    // instead of letting it hang off the side.
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    ParallelAnimation {
        id: show
        NumberAnimation {
            target: card; property: "opacity"
            from: 0; to: 1
            duration: Theme.openDuration; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: slide; property: "y"
            from: -Theme.openSlide; to: 0
            duration: Theme.openDuration; easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.dropGap
        width: root.contentWidth
        height: parent.height - root.dropGap - root.pad
        transform: Translate { id: slide }
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
