import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "root:/"

// Bluetooth picker, opened by clicking the bar's bluetooth icon. waybar's
// module could only shell out to blueman-manager; this is BlueZ over the bus.
PopupShell {
    id: root

    contentWidth: 340

    readonly property var adapter: Bluetooth.defaultAdapter

    // Discovery costs radio time and battery, so it only runs while the list
    // is open, and stops again the moment it closes.
    onVisibleChanged: if (adapter && adapter.enabled) adapter.discovering = visible
    Component.onDestruction: if (adapter) adapter.discovering = false

    Item {
        width: parent.width
        implicitHeight: 26

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Bluetooth"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 17
            font.weight: Font.Bold
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 42
            height: 22
            radius: Theme.pillRadius
            color: root.adapter?.enabled ? Theme.accent : Theme.overlay

            Rectangle {
                width: 16
                height: 16
                radius: Theme.pillRadius
                color: Theme.bg
                anchors.verticalCenter: parent.verticalCenter
                x: root.adapter?.enabled ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const a = root.adapter;
                    if (!a) return;
                    a.enabled = !a.enabled;
                    a.discovering = a.enabled;
                }
            }
        }
    }

    Text {
        width: parent.width
        visible: !root.adapter || !root.adapter.enabled
        text: !root.adapter ? "No adapter" : "Bluetooth is off"
        color: Theme.fgDim
        opacity: 0.45
        horizontalAlignment: Text.AlignHCenter
        topPadding: 24
        bottomPadding: 24
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelFontSize
    }

    Repeater {
        model: ScriptModel {
            // Connected first, then paired, then whatever discovery turns up.
            // Nameless devices are dropped: a bare MAC address is not
            // something anyone can pick out of a list.
            values: {
                const a = root.adapter;
                if (!a || !a.enabled) return [];
                return [...a.devices.values]
                    .filter(d => (d.name ?? "") !== "")
                    .sort((x, y) => (y.connected - x.connected)
                                 || (y.paired - x.paired)
                                 || x.name.localeCompare(y.name));
            }
        }

        delegate: PopupRow {
            required property var modelData

            glyph: modelData.connected ? "󰂱" : "󰂯"
            label: modelData.name
            detail: modelData.pairing ? "pairing..."
                  : modelData.connected
                    ? (modelData.batteryAvailable
                        ? Math.round(modelData.battery * 100) + "%" : "connected")
                  : modelData.paired ? "paired" : ""
            highlight: modelData.connected

            onActivated: {
                if (modelData.connected) modelData.disconnect();
                else if (modelData.paired) modelData.connect();
                else modelData.pair();
            }
            // Right click forgets, which is the only way back from a device
            // that paired badly.
            onSecondary: if (modelData.paired) modelData.forget()
        }
    }

    Text {
        width: parent.width
        visible: root.adapter?.discovering ?? false
        text: "Scanning..."
        color: Theme.fgDim
        opacity: 0.45
        topPadding: 6
        horizontalAlignment: Text.AlignHCenter
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelFontSize - 2
    }
}
