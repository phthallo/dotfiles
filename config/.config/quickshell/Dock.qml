import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/"

// nwg-dock-hyprland, as launched from hyprland.conf:
//     nwg-dock-hyprland -x -nolauncher -mb 10 -s style.css
// -x is an exclusive zone (so it is always visible and pushes tiled windows
// up), -nolauncher drops the drawer button, -mb 10 is the bottom margin, and
// the icon size is the 48px default. Colours and radii come from its
// style.css, which is hand-written gruvbox rather than themed - the values
// are mapped onto theme tokens here so the dock follows a theme switch,
// which the original never did.
//
// One deliberate departure: nwg-dock drew a button per window, so five
// terminals meant five identical icons. Here windows are grouped by app and
// the count is drawn as dots under the icon instead.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors.bottom: true
    margins.bottom: 10
    color: "transparent"

    implicitWidth: dock.implicitWidth
    implicitHeight: dock.implicitHeight
    // wlr-foreign-toplevel rather than Hyprland's list: it is populated from
    // connect (Hyprland.toplevels starts empty until refreshToplevels), it
    // carries every window rather than the ones Hyprland last reported, and
    // appId/activate()/close() are all this needs - so the dock has no
    // compositor-specific code in it at all.
    readonly property var windows: [...ToplevelManager.toplevels.values]

    // Grouped by app, in the order each app first appeared, so a button does
    // not jump along the row when a window somewhere else in it closes.
    // Both halves come out of one pass: the delegates need the map to find
    // their own windows, the Repeater needs the keys in order.
    //
    // A window with no appId gets a key of its own rather than joining a
    // shared "" group - unrelated nameless windows are not the same app.
    readonly property var grouped: {
        const map = ({});
        const keys = [];
        const ws = windows;
        for (let i = 0; i < ws.length; i++) {
            const key = ws[i].appId || ("window:" + i);
            if (!map[key]) {
                map[key] = [];
                keys.push(key);
            }
            map[key].push(ws[i]);
        }
        return { map, keys };
    }

    // Nothing to reserve when nothing is running - an empty dock would
    // otherwise hold a strip of screen for a box with no buttons in it.
    // ScriptModel has no count property, so this asks the array itself.
    visible: windows.length > 0
    exclusiveZone: visible ? implicitHeight + margins.bottom : 0

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:dock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ScriptModel rather than the bare array: it diffs, so a window opening
    // somewhere else does not rebuild every button and reload every icon.
    // The model carries the keys, not the group objects - a group's contents
    // change every time one of its windows opens or closes, and a delegate
    // that re-reads the map by key stays put through that instead of being
    // torn down and rebuilt.
    ScriptModel {
        id: toplevels
        values: root.grouped.keys
    }

    Rectangle {
        id: dock
        anchors.centerIn: parent
        implicitWidth: row.implicitWidth + 20    // #box padding: 10px
        implicitHeight: row.implicitHeight + 20
        radius: 10
        color: Theme.surface                     // #3c3836
        border.width: 1
        border.color: Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.4)

        // Row, not RowLayout: the box is sized by its contents here, and a
        // layout asked to fill a width it is itself defining spreads the
        // buttons to the ends instead of packing them.
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8                           // 4px margin either side

            Repeater {
                model: toplevels

                delegate: Rectangle {
                    id: button
                    required property string modelData

                    // Re-read out of the map by key rather than held: the
                    // delegate survives its group gaining and losing windows.
                    readonly property var group:
                        root.grouped.map[modelData] ?? []
                    readonly property string appClass: group[0]?.appId ?? ""
                    readonly property bool active:
                        group.some(w => w.activated)

                    implicitWidth: 56                // 48px icon + 4px padding
                    implicitHeight: 64               // + the dot row below it
                    // Rounded a little more than nwg-dock's near-square 2px:
                    // that was fine for a faint hover wash, but the focused
                    // button is a solid block of colour and reads as a patch
                    // rather than a button at that radius.
                    radius: 6
                    // The focused app's button is lit in the theme's blue,
                    // hover in plain white: two different questions ("which
                    // window am I in" vs "what is under the pointer"), so
                    // they get two different colours rather than two
                    // strengths of the same one, which would read as the
                    // hovered button being the focused one.
                    color: button.active
                        ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b,
                                  mouse.containsMouse ? 0.70 : 0.55)
                        : Qt.rgba(1, 1, 1, mouse.containsMouse ? 0.15 : 0)

                    Image {
                        id: icon
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 48
                        height: 48
                        sourceSize.width: 48
                        sourceSize.height: 48
                        asynchronous: true

                        // No way to stat a path from QML, so the fallback
                        // chain is walked by failing: each source that will
                        // not load hands over to the next.
                        readonly property var candidates:
                            Icons.appIconCandidates(button.appClass)
                        property int attempt: 0
                        source: candidates[Math.min(attempt,
                                                    candidates.length - 1)]
                        onStatusChanged: {
                            if (status === Image.Error
                                    && attempt < candidates.length - 1)
                                attempt++;
                        }
                    }

                    // One dot per window, which is the whole point of the
                    // grouping - the row says how many are open without
                    // repeating the icon. This replaces nwg-dock's #active
                    // underline rather than sitting beside it: both want the
                    // same strip of pixels, and colour carries the active
                    // state just as well (blue for the group holding the
                    // focused window, muted for the rest).
                    //
                    // Capped at four. Past that the dots stop being countable
                    // at a glance and just become a smear.
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 3

                        Repeater {
                            model: Math.min(button.group.length, 4)

                            delegate: Rectangle {
                                width: 4
                                height: 4
                                radius: 2
                                color: button.active
                                    ? Theme.blue
                                    : Qt.rgba(Theme.fg.r, Theme.fg.g,
                                              Theme.fg.b, 0.45)
                            }
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        // Left click raises the group's window; clicking a
                        // group that already holds focus steps to its next
                        // window, so a stack of terminals is walked with
                        // repeated clicks instead of being stuck on one.
                        // Middle click closes only the focused member, never
                        // the whole group - one misclick should not take five
                        // windows with it.
                        onClicked: event => {
                            const g = button.group;
                            if (g.length === 0)
                                return;

                            const at = g.findIndex(w => w.activated);
                            if (event.button === Qt.MiddleButton)
                                g[Math.max(at, 0)].close();
                            else
                                g[(at + 1) % g.length].activate();
                        }
                    }
                }
            }
        }
    }
}
