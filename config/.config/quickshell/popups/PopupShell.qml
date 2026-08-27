import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"

// Shared chrome for the small panels the bar drops down: same surface,
// border and radius as the control centre, and now the same dismiss
// mechanism too - a plain layer surface with its own backdrop, not an
// xdg-popup grab.
//
// grabFocus used to make this an xdg popup with a pointer grab. That grab
// is tied to Hyprland's focus/keyboard state, and a workspace switch moves
// both, so the compositor tore the popup down on its own the moment a
// workspace keybind fired - wifi/bluetooth/theme closed themselves out from
// under a switch that never touched the popup. A hand-rolled backdrop, like
// the control centre already uses, only closes on an actual outside click.
Scope {
    id: root

    default property alias content: inner.data
    property int contentWidth: 320
    property bool open: false
    // Mirrors `open` under the old PopupWindow's name - callers gate
    // side effects (wifi scanning, bluetooth discovery) on this.
    readonly property bool visible: open

    property Item anchorItem: null

    readonly property int dropGap: Theme.gap

    readonly property var anchorWindow: root.anchorItem?.QsWindow?.window ?? null
    readonly property var anchorScreen: root.anchorWindow?.screen ?? null

    // A layer surface never gets a focus-out from a plain click, so "click
    // outside to close" needs an actual surface to catch it. Left off the
    // bar strip on purpose: the bar and this backdrop are both WlrLayer.Top,
    // so which one actually catches a click over the bar is down to
    // compositor stacking order, not anything this file controls - a click
    // meant for the icon that reopens/closes it could land on either one.
    // Starting the backdrop below the bar removes the ambiguity: a click on
    // the bar always reaches the bar.
    // Hyprland bug, not ours: a freshly-mapped surface doesn't get pointer
    // focus until the pointer physically moves, so the first click after a
    // surface maps or unmaps (including the click meant to close this popup
    // again) is silently dropped. hyprwm/Hyprland#4882, still open.
    // Re-issuing the cursor's own position is a no-op visually but fires
    // the motion event Hyprland needs to reassess focus. Both the backdrop
    // and the panel map/unmap independently, so both need the nudge.
    Process {
        id: refocusCursor
        command: ["sh", "-c",
            "hyprctl dispatch movecursor \"$(hyprctl cursorpos | tr -d ',')\""]
    }

    PanelWindow {
        screen: root.anchorScreen
        visible: root.open && root.anchorScreen !== null
        onVisibleChanged: refocusCursor.running = true
        anchors { top: true; bottom: true; left: true; right: true }
        margins.top: Theme.barHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:popup-backdrop"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }
    }

    PanelWindow {
        id: panel
        screen: root.anchorScreen
        visible: root.open && root.anchorScreen !== null
        onVisibleChanged: {
            refocusCursor.running = true;
            if (visible) { place(); show.restart(); escScope.forceActiveFocus(); }
            else if (root.open)
                root.open = false;
        }

        anchors { top: true; left: true }
        margins.top: Theme.gap
        margins.left: Theme.gap

        implicitWidth: contentWidth
        implicitHeight: Math.min(600, inner.implicitHeight + 2 * Theme.panelPad)
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        // Normal (as used by the control centre) would double-offset this:
        // place() below already computes an absolute position past the bar
        // via mapToItem, so Normal's own exclusive-zone push stacks on top
        // of that and drags the popup further down/right than intended.
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        // Placed by hand rather than left to an anchor: the theme switcher
        // lives right in the left island and needs to land under it, not
        // wherever a generic edge anchor would slide it. Run on open only -
        // bar items can't move while a click-to-dismiss backdrop holds it.
        function place(): void {
            const item = root.anchorItem;
            const win = root.anchorWindow;
            if (!item || !win)
                return;

            const pos = item.mapToItem(null, 0, 0);
            const half = contentWidth / 2;
            const centre = Math.max(Theme.gap + half,
                Math.min(pos.x + item.width / 2, win.width - Theme.gap - half));

            margins.left = centre - half;
            margins.top = pos.y + item.height + root.dropGap;
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

        FocusScope {
            id: escScope
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.open = false

            Rectangle {
                id: card
                anchors.fill: parent
                transform: Translate { id: slide }
                color: Theme.bg
                radius: Theme.panelRadius
                border.width: Theme.borderWidth
                border.color: Theme.borderActive

                // The 600px cap above bounds the window, not the content -
                // without this, a longer wifi list just ran off the bottom,
                // unreachable. interactive only while it overflows, so a
                // short list doesn't drift.
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
    }
}
