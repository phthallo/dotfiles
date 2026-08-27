import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

// waybar's hyprland/workspaces, all-outputs with numeric icons and a bullet
// fallback. Scroll steps through workspaces without wraparound, which is what
// disable-scroll-wraparound did.
RowLayout {
    id: root
    spacing: 8

    Repeater {
        model: Hyprland.workspaces

        BarText {
            required property var modelData

            readonly property bool active:
                Hyprland.focusedWorkspace?.id === modelData.id

            // format-icons mapped 1-6 to themselves and everything else to a
            // bullet, so the bar stays a fixed width once you go past six.
            text: modelData.id >= 1 && modelData.id <= 6 ? modelData.id : "•"
            color: active ? Theme.accent : Theme.fgDim
            font.bold: active

            onLeft: () => Hyprland.dispatch("workspace " + modelData.id)
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            const step = event.angleDelta.y > 0 ? "e-1" : "e+1";
            Hyprland.dispatch("workspace " + step);
        }
    }
}
