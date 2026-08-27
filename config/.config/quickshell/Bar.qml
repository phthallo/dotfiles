import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "modules"

// One transparent PanelWindow per monitor; each module group gets its own
// Island for background/border, mirroring waybar's .modules-left/center/right.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    color: "transparent"
    implicitHeight: Theme.barHeight

    anchors {
        top: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:bar"

    // Hyprland.toplevels starts empty until refreshToplevels() runs, so
    // without this the window title stays blank until something else triggers
    // a refresh.
    Component.onCompleted: Hyprland.refreshToplevels()

    Item {
        anchors.fill: parent
        anchors.topMargin: Theme.gap
        anchors.leftMargin: Theme.gap
        anchors.rightMargin: Theme.gap

        Island {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Group {
                Launcher {}
                IdleInhibitor { window: root }
                Separator {}
                ThemeSwitcher {}
            }

            // The only bar items with no brackets of their own. No margins
            // anywhere in the bar - spacing comes from each item's own
            // padding meeting the next (Theme.itemPad).
            Workspaces {}

            MprisWidget {}
        }

        Island {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            visible: title.text !== ""

            Group {
                WindowTitle { id: title }
            }
        }

        Island {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Group {
                SysInfo { kind: "cpu" }
                Separator {}
                SysInfo { kind: "memory" }
            }

            Group {
                Clock {}
                Separator {}
                Network {}
                Bluetooth {}
                Battery {}
                NotificationBell {}
            }
        }
    }
}
