import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/"
import "panels"

// The floating toast stack: swaync's positionX/positionY "right"/"top" on the
// overlay layer, notification-window-width 420.
//
// The window spans the whole right column so cards can grow and shrink
// without resizing a surface every frame; `mask` keeps the empty part of it
// click-through, so this does not swallow clicks meant for the desktop.
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
    // Toasts must never take the keyboard from what you are typing in.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

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

                // Critical notifications get timeout 0 and stay until they are
                // clicked, which is swaync's default and the reason a battery
                // warning does not vanish while you are away from the screen.
                Timer {
                    interval: Notifications.timeoutFor(parent.modelData)
                    running: interval > 0
                    onTriggered: Notifications.expire(parent.modelData)
                }

                // Toasts fade rather than appear: a card popping in at full
                // opacity beside the pointer reads as a misclick.
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }
}
