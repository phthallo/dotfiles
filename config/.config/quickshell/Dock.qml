import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "root:/"

// Replaces nwg-dock-hyprland. One departure from it: windows are grouped by
// app and the count is drawn as dots under the icon, instead of one button
// per window.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors.bottom: true
    margins.bottom: 10
    color: "transparent"

    implicitWidth: dock.implicitWidth
    implicitHeight: dock.implicitHeight
    // wlr-foreign-toplevel rather than Hyprland's list: it's populated on
    // connect and carries every window, not just what Hyprland last reported.
    readonly property var windows: [...ToplevelManager.toplevels.values]

    // Workspace membership isn't in the wlr protocol, so it has to come from
    // Hyprland. HyprlandToplevel.wayland is the same object ToplevelManager
    // hands out, so the two lists join on identity.
    //
    // Unknown workspace sorts last, and as a large number rather than
    // Infinity - two unknowns subtracting gives NaN, which sort() can't use.
    readonly property int unknownWorkspace: 1e9
    readonly property var workspaceOf: {
        const m = new Map();
        for (const t of Hyprland.toplevels.values)
            if (t.wayland)
                m.set(t.wayland, t.workspace?.id ?? root.unknownWorkspace);
        return m;
    }

    // Groups ordered by the lowest workspace any of their windows sits on,
    // ties by first-seen order (so a button doesn't jump when a window
    // elsewhere in its group closes). A window with no appId gets its own key
    // rather than joining a shared "" group.
    readonly property var grouped: {
        const map = ({});
        const rank = ({});
        const ws = windows;
        for (let i = 0; i < ws.length; i++) {
            const key = ws[i].appId || ("window:" + i);
            const at = workspaceOf.get(ws[i]) ?? root.unknownWorkspace;
            if (!map[key]) {
                map[key] = [];
                rank[key] = { ws: at, first: i };
            }
            map[key].push(ws[i]);
            rank[key].ws = Math.min(rank[key].ws, at);
        }
        const keys = Object.keys(map).sort((a, b) =>
            rank[a].ws - rank[b].ws || rank[a].first - rank[b].first);
        for (const key of keys)
            map[key].sort((a, b) =>
                (workspaceOf.get(a) ?? root.unknownWorkspace)
                - (workspaceOf.get(b) ?? root.unknownWorkspace));
        return { map, keys };
    }

    visible: windows.length > 0
    exclusiveZone: visible ? implicitHeight + margins.bottom : 0

    // Hyprland's toplevel list starts empty until this runs; the event socket
    // keeps it current after that.
    Component.onCompleted: Hyprland.refreshToplevels()

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:dock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ScriptModel diffs, so a window opening elsewhere doesn't rebuild every
    // button. Carries the group keys, not the groups themselves, so a
    // delegate re-reads its group by key and survives its contents changing.
    ScriptModel {
        id: toplevels
        values: root.grouped.keys
    }

    Rectangle {
        id: dock
        anchors.centerIn: parent
        implicitWidth: row.implicitWidth + 20
        implicitHeight: row.implicitHeight + 20
        radius: 10
        color: Theme.surface
        border.width: 1
        border.color: Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.4)

        // Row, not RowLayout: the box is sized by its contents, and a layout
        // asked to fill a width it's itself defining spreads buttons to the
        // ends instead of packing them.
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: toplevels

                delegate: Rectangle {
                    id: button
                    required property string modelData

                    readonly property var group:
                        root.grouped.map[modelData] ?? []
                    readonly property string appClass: group[0]?.appId ?? ""
                    readonly property bool active:
                        group.some(w => w.activated)

                    implicitWidth: 56
                    implicitHeight: 64
                    radius: 6
                    // Focus in blue, hover in white - two different questions
                    // ("which window am I in" vs "what's under the pointer"),
                    // so two colours rather than two strengths of one.
                    color: Qt.rgba(1, 1, 1, mouse.containsMouse ? 0.15 : 0)

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

                        // QML can't stat a path, so the fallback chain is
                        // walked by failing: each source that won't load
                        // hands over to the next.
                        readonly property var candidates:
                            Icons.appIconCandidates(button.appClass)
                        property int attempt: 0
                        // Reset on a new list, so a theme switch that makes an
                        // earlier candidate resolve isn't stuck on the old
                        // fallback.
                        onCandidatesChanged: attempt = 0
                        source: candidates[Math.min(attempt,
                                                    candidates.length - 1)]
                        onStatusChanged: {
                            if (status === Image.Error
                                    && attempt < candidates.length - 1)
                                attempt++;
                        }
                    }

                    // One dot per window, capped at three - past that they
                    // stop being countable at a glance.
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 3

                        Repeater {
                            model: Math.min(button.group.length, 3)

                            delegate: Rectangle {
                                width: button.active ? 6 : 4
                                height: button.active ? 6 : 4
                                radius: width / 2
                                anchors.verticalCenter: parent.verticalCenter
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
                        // Left click raises the group's window, or steps to
                        // the next one if it's already focused. Middle click
                        // closes only the focused member.
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
