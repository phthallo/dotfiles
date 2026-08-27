import QtQuick
import QtQuick.Layouts
import Quickshell
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
    // Height is the island height plus the gap above it. The bar reserves
    // this much space, which is what waybar's height:50 plus margin-top:20
    // added up to.
    implicitHeight: Theme.barHeight + Theme.gap

    anchors {
        top: true
        left: true
        right: true
    }

    // Above normal windows but below dialogs, matching waybar's default.
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:bar"

    Item {
        anchors.fill: parent
        anchors.topMargin: Theme.gap
        anchors.leftMargin: Theme.gap
        anchors.rightMargin: Theme.gap

        Island {
            id: leftIsland
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Launcher {}
            Separator {}
            IdleInhibitor { window: root }
            Separator {}
            ThemeSwitcher {}
        }

        // Workspaces and the media widget sat outside the left island in
        // waybar - bare modules between the groups - so they stay outside it.
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: leftIsland.width + Theme.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gap

            Workspaces {}
            MprisWidget {}
        }

        Island {
            id: centreIsland
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            visible: title.text !== ""

            WindowTitle { id: title }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gap

            Island {
                SysInfo { kind: "cpu" }
                Separator {}
                SysInfo { kind: "memory" }
            }

            Island {
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
