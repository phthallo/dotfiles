import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/"
import "panels"

// The floating toast stack, matching swaync's top-right overlay positioning.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.right: true
    margins.top: Theme.gap
    margins.right: Theme.gap

    implicitWidth: Theme.panelWidth
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"
    visible: Notifications.popups.length > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Keeps the empty part of the window click-through, so it doesn't
    // swallow clicks meant for the desktop.
    mask: Region { item: column }

    ColumnLayout {
        id: column
        anchors.top: parent.top
        anchors.right: parent.right
        width: Theme.panelWidth
        spacing: Theme.cardGap

        Repeater {
            model: Notifications.popups

            delegate: Item {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: card.implicitHeight

                NotifCard {
                    id: card
                    notif: parent.modelData
                    cardWidth: Theme.panelWidth
                    onClosed: Notifications.expire(parent.modelData)
                }

                Timer {
                    interval: Notifications.timeoutFor(parent.modelData)
                    running: interval > 0
                    onTriggered: Notifications.expire(parent.modelData)
                }

                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }
}
