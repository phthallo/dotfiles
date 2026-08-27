import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "root:/"

// waybar's hyprland/workspaces, all-outputs with numeric icons and a bullet
// fallback. Scroll steps through workspaces without wraparound, which is what
// disable-scroll-wraparound did.
//
// The MouseArea is the root rather than an overlay: a RowLayout manages its
// children's geometry, so anchoring a filling MouseArea inside one is
// undefined behaviour (Qt says so out loud). Wrapping instead sidesteps it.
MouseArea {
    id: root

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    acceptedButtons: Qt.NoButton
    onWheel: event => {
        // e+1 / e-1 are Hyprland's "next/previous existing workspace", which
        // is the no-wraparound behaviour waybar was configured for.
        Hyprland.dispatch("workspace " + (event.angleDelta.y > 0 ? "e-1" : "e+1"));
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8

        Repeater {
            // Hyprland returns workspaces in creation order, not numeric
            // order, so a bar built straight off it reads "3 1 2 4 5"
            // after you have jumped around.
            model: [...Hyprland.workspaces.values].sort((a, b) => a.id - b.id)

            BarText {
                required property var modelData

                readonly property bool active:
                    Hyprland.focusedWorkspace?.id === modelData.id

                // format-icons mapped 1-6 to themselves and everything else to
                // a bullet, so the bar stays a fixed width past six.
                text: modelData.id >= 1 && modelData.id <= 6 ? modelData.id : "•"
                color: active ? Theme.accent : Theme.fgDim
                font.bold: active

                onLeft: () => Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}
