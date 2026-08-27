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

    // Always drawn, whether or not Hyprland has created them yet. waybar
    // listed only the workspaces that existed, so the bar grew a cell the
    // first time you visited a new one and lost it again when you left,
    // shoving everything to its right along each time.
    readonly property int persistent: 5

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
            // Ids rather than workspace objects, because the persistent
            // ones have no object until Hyprland creates them. Anything
            // Hyprland does have beyond them is appended, so a sixth
            // workspace still shows up while you are on it.
            //
            // Sorted, because Hyprland returns workspaces in creation order
            // and a bar built straight off it reads "3 1 2 4 5" once you
            // have jumped around. Negative ids are the special workspaces
            // (the scratchpad), which never had a cell here.
            model: {
                const ids = new Set();
                for (let i = 1; i <= root.persistent; i++)
                    ids.add(i);
                for (const w of Hyprland.workspaces.values)
                    if (w.id > 0)
                        ids.add(w.id);
                return [...ids].sort((a, b) => a - b);
            }

            BarText {
                required property int modelData

                readonly property bool active:
                    Hyprland.focusedWorkspace?.id === modelData

                // format-icons mapped each workspace to its own numeral and
                // everything else to a bullet, so the bar stays a fixed
                // width however far past the end you go.
                text: modelData <= root.persistent ? modelData : "•"

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

                onLeft: () => Hyprland.dispatch("workspace " + modelData)
            }
        }
    }
}
