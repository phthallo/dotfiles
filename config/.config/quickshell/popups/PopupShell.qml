import QtQuick
import Quickshell
import "root:/"

// Shared chrome for the small panels the bar drops down: same surface, border
// and radius as the control center, so a wifi list and the theme picker read
// as the same window at different sizes.
//
// grabFocus makes this an xdg popup with a pointer grab, so a click outside
// dismisses it - something a layer surface (like wofi) can never see.
PopupWindow {
    id: root

    default property alias content: inner.data
    property int contentWidth: 320

    readonly property int dropGap: Theme.gap

    // Callers flip `open`, never `visible`. The compositor closes a grabbing
    // popup on its own on an outside click, so a one-way `visible: open`
    // binding goes stale and the button needs two clicks to reopen. Syncing
    // both directions keeps it an honest toggle instead.
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

    // Placed by hand rather than left to the anchor: SlideX only guarantees
    // the window lands on screen, not gaps_out from the edge, and the theme
    // switcher lives right in the left island. Run once per open - bar items
    // can't move while a grabbing popup holds the pointer.
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

        // The 600px cap above bounds the window, not the content - without
        // this, a longer wifi list just ran off the bottom, unreachable.
        // interactive only while it overflows, so a short list doesn't drift.
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
