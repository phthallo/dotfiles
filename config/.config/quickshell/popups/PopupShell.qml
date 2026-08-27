import QtQuick
import Quickshell
import "root:/"

// Shared chrome for the small panels the bar drops down: same surface, border
// and radius as the control center, so a wifi list and the theme picker read
// as the same window at different sizes.
//
// grabFocus makes this an xdg popup with a pointer grab, so a click anywhere
// outside dismisses it. That is the thing wofi could never do as a layer
// surface - a layer surface never sees the focus-out.
PopupWindow {
    id: root

    default property alias content: inner.data
    property int contentWidth: 320

    // Theme.gap below the bar, matching gaps_out, so a popup lines up with
    // the top edge of the tiled windows beside it and with the control
    // center.
    readonly property int dropGap: Theme.gap

    // Callers flip `open`, never `visible`. The compositor closes a grabbing
    // popup on its own when a click lands outside it, so a `visible: open`
    // binding would go stale and the next click on the bar button would only
    // toggle the flag back - the classic two-clicks-to-reopen bug. Syncing
    // both directions instead keeps the button an honest toggle: clicking it
    // again is itself an outside click, the grab eats it, the surface goes,
    // and this sees that and clears the flag.
    property bool open: false
    onOpenChanged: {
        if (open) place();
        if (visible !== open) visible = open;
    }
    onVisibleChanged: {
        if (open !== visible) open = visible;
        if (visible) show.restart();
    }

    implicitWidth: contentWidth
    implicitHeight: Math.min(600, inner.implicitHeight + 2 * Theme.panelPad)
    color: "transparent"
    grabFocus: true

    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX

    // Placed by hand rather than left to the anchor, because centring a popup
    // under a bar item near the edge puts its border flush against the screen
    // - and the theme switcher lives in the left island, so it always was.
    // SlideX only promises the window lands *on* screen, not gaps_out from
    // it. Masking a wider window down to a padded card is the other way to
    // do this and works fine - a Region mask does pass the clicks outside it
    // through, checked directly - but a window that is already the size of
    // what it draws needs no mask at all, so this does that instead.
    //
    // Run once per open: bar items only move when the bar relayouts, which
    // cannot happen while a grabbing popup holds the pointer.
    function place(): void {
        const item = anchor.item;
        const win = item?.QsWindow?.window ?? null;
        if (!item || !win)
            return;

        const pos = item.mapToItem(null, 0, 0);
        const half = root.implicitWidth / 2;
        const centre = Math.max(Theme.gap + half,
                                Math.min(pos.x + item.width / 2,
                                         win.width - Theme.gap - half));

        anchor.rect.x = centre - pos.x;
        anchor.rect.y = item.height + root.dropGap;
        anchor.rect.width = 0;
        anchor.rect.height = 0;
    }

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
        anchors.fill: parent
        transform: Translate { id: slide }
        color: Theme.bg
        radius: Theme.panelRadius
        border.width: Theme.borderWidth
        border.color: Theme.borderActive

        // The height cap above is a cap on the window, not on the content:
        // without something to scroll, a wifi list longer than 600px simply
        // ran off the bottom edge and the networks past it could not be
        // reached at all. interactive only while it overflows, so a short
        // list does not drift under the pointer.
        Flickable {
            id: scroll
            anchors.fill: parent
            anchors.margins: Theme.panelPad
            contentHeight: inner.implicitHeight
            interactive: contentHeight > height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: inner
                width: scroll.width
                spacing: Theme.cardGap
            }
        }
    }
}
