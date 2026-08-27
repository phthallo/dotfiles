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
    // The button strip is as tall as the island's interior, so the active
    // cell reads as a filled column rather than a chip floating in the middle.
    implicitHeight: Theme.islandHeight - 2 * Theme.borderWidth

    acceptedButtons: Qt.NoButton
    onWheel: event => {
        // e+1 / e-1 are Hyprland's "next/previous existing workspace", which
        // is the no-wraparound behaviour waybar was configured for.
        Hyprland.dispatch("workspace " + (event.angleDelta.y > 0 ? "e-1" : "e+1"));
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 0   // waybar spaced these with 8px of button padding, below

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

                // #workspaces button.active: a filled block behind dimmed
                // text, not brighter text. Reading it the other way round is
                // what made the port look wrong - the active workspace was an
                // orange numeral instead of a highlighted cell.
                color: active ? Theme.fgDim : Theme.fg
                chipColor: active ? Theme.surface : "transparent"
                chipRadius: 0        // border-radius: 0 on these

                // Padded like every other bar item, which also sets how
                // far the active workspace's filled cell extends past
                // its numeral.
                // Layout.fillHeight, not height: inside a RowLayout the layout
                // owns geometry and a plain height assignment is discarded.
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter

                onLeft: () => Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}
