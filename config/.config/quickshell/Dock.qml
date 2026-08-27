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

    // Nothing to reserve when nothing is running - an empty dock would
    // otherwise hold a strip of screen for a box with no buttons in it.
    // ScriptModel has no count property, so this asks the array itself.
    visible: windows.length > 0
    exclusiveZone: visible ? implicitHeight + margins.bottom : 0

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:dock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ScriptModel rather than the bare array: it diffs by identity, so a
    // window opening somewhere else does not rebuild every button and reload
    // every icon.
    ScriptModel {
        id: toplevels
        values: root.windows
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
                    required property var modelData

                    readonly property string appClass: modelData.appId ?? ""
                    readonly property bool active: modelData.activated

                    implicitWidth: 56                // 48px icon + 4px padding
                    implicitHeight: 56
                    radius: 2
                    color: mouse.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

                    Image {
                        id: icon
                        anchors.centerIn: parent
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

                    // #active: solid 1px underline in the theme's blue.
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 8
                        height: 1
                        color: Theme.blue
                        visible: button.active
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: event => {
                            if (event.button === Qt.MiddleButton)
                                button.modelData.close();
                            else
                                button.modelData.activate();
                        }
                    }
                }
            }
        }
    }
}
