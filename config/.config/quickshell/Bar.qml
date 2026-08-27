import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "modules"

// The bar, one per monitor.
//
// waybar drew a single transparent full-width surface and gave its three
// module groups their own backgrounds, margins and borders, which is why the
// stylesheet had .modules-left/.modules-center/.modules-right each repeating
// the same box. Same result here, but the transparent surface is the
// PanelWindow and each group is an Island.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    color: "transparent"
    // waybar reserved 50px total and pushed its groups down 20 into it, so
    // the islands are 30 tall inside a 50 strip.
    implicitHeight: Theme.barHeight

    anchors {
        top: true
        left: true
        right: true
    }

    // Above normal windows but below dialogs, matching waybar's default.
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:bar"

    // Hyprland.toplevels starts empty and is only filled on request, so
    // without this the window title stays blank until something else happens
    // to trigger a refresh - on a quiet desktop, a long wait. It lives here
    // rather than in shell.qml because ShellRoot has no attached Component
    // signals; on a multi-monitor setup it just runs once per bar, which is
    // harmless since the call is idempotent.
    Component.onCompleted: Hyprland.refreshToplevels()

    Item {
        anchors.fill: parent
        anchors.topMargin: Theme.gap
        anchors.leftMargin: Theme.gap
        anchors.rightMargin: Theme.gap

        // One background behind the utilities group, the workspace buttons
        // and the media group, the way .modules-left was.
        Island {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Group {
                Launcher {}
                IdleInhibitor { window: root }
                Separator {}
                ThemeSwitcher {}
            }

            // Bare buttons between the two groups, with no brackets of their
            // own - the only part of the bar that is not inside a group.
            // No margins here or anywhere else in the bar: spacing is one
            // item's padding meeting the next one's. See Theme.itemPad.
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
