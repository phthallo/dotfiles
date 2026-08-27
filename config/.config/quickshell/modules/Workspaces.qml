import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "root:/"

// waybar's hyprland/workspaces, all-outputs with numeric icons and a bullet
// fallback. Scroll steps through workspaces without wraparound.
//
// MouseArea is the root, not an overlay: anchoring a filling MouseArea inside
// a RowLayout is undefined behaviour in Qt. Wrapping the layout sidesteps it.
MouseArea {
    id: root

    // Always drawn whether or not Hyprland has created them, so the bar
    // doesn't grow/shrink a cell as you visit new workspaces.
    readonly property int persistent: 5

    implicitWidth: layout.implicitWidth
    // As tall as the island's interior, so the active cell reads as a filled
    // column rather than a floating chip.
    implicitHeight: Theme.islandHeight - 2 * Theme.borderWidth

    acceptedButtons: Qt.NoButton
    onWheel: event => {
        // e+1/e-1: Hyprland's next/previous-existing-workspace, no wraparound.
        Hyprland.dispatch("workspace " + (event.angleDelta.y > 0 ? "e-1" : "e+1"));
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 0

        Repeater {
            // Ids, not workspace objects - the persistent ones have no object
            // until Hyprland creates them. Sorted, since Hyprland returns
            // workspaces in creation order. Negative ids are the scratchpad
            // and never get a cell. Past the persistent five, a bullet (id 0,
            // never used by Hyprland, so it's unclickable) marks where the
            // overflow starts.
            model: {
                const ids = new Set();
                for (let i = 1; i <= root.persistent; i++)
                    ids.add(i);
                for (const w of Hyprland.workspaces.values)
                    if (w.id > 0)
                        ids.add(w.id);
                const out = [...ids].sort((a, b) => a - b);
                if (out.length > root.persistent)
                    out.push(0);
                return out;
            }

            BarText {
                required property int modelData

                readonly property bool active:
                    Hyprland.focusedWorkspace?.id === modelData

                text: modelData > 0 ? modelData : "•"

                // #workspaces button.active: a filled block behind dimmed
                // text, not brighter text.
                color: active ? Theme.fgDim : Theme.fg
                chipColor: active ? Theme.surface : "transparent"
                chipRadius: 0

                // Layout.fillHeight, not height: inside a RowLayout the
                // layout owns geometry and a plain height assignment is
                // discarded.
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter

                onLeft: modelData > 0
                    ? () => Hyprland.dispatch("workspace " + modelData)
                    : null
            }
        }
    }
}
