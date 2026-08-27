import QtQuick
import Quickshell
import Quickshell.Networking
import "root:/"

// Wifi picker, opened by clicking the bar's network icon. waybar could only
// launch `kitty -e nmtui`; this talks to the same NetworkManager over the bus.
PopupShell {
    id: root

    contentWidth: 340

    readonly property var wifi: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi) return d;
        return null;
    }

    // Scanning is the expensive part of a wifi list, so the radio is only
    // told to scan while the popup is actually on screen.
    onVisibleChanged: if (wifi) wifi.scannerEnabled = visible
    Component.onDestruction: if (wifi) wifi.scannerEnabled = false

    Item {
        width: parent.width
        implicitHeight: 26

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Wi-Fi"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 17
            font.weight: Font.Bold
        }

        // Same pill as a control-center toggle, sized for a header.
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 42
            height: 22
            radius: Theme.pillRadius
            color: Networking.wifiEnabled ? Theme.accent : Theme.raised

            Rectangle {
                width: 16
                height: 16
                radius: Theme.pillRadius
                color: Theme.bg
                anchors.verticalCenter: parent.verticalCenter
                x: Networking.wifiEnabled ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }
    }

    Text {
        width: parent.width
        visible: !Networking.wifiEnabled || !root.wifi
        text: !root.wifi ? "No wifi device" : "Wi-Fi is off"
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
            // Strongest first, and one row per SSID - NetworkManager reports
            // every access point, so a mesh network would otherwise fill the
            // list with the same name five times.
            values: {
                if (!root.wifi || !Networking.wifiEnabled) return [];
                const best = new Map();
                for (const n of root.wifi.networks.values) {
                    const prev = best.get(n.name);
                    if (!prev || n.signalStrength > prev.signalStrength)
                        best.set(n.name, n);
                }
                return [...best.values()].sort((a, b) =>
                    (b.connected - a.connected) || (b.signalStrength - a.signalStrength));
            }
        }

        delegate: PopupRow {
            required property var modelData

            // Same five-bar ramp waybar used, so the popup and the bar icon
            // never disagree about how strong the signal is.
            glyph: ["󰤯", "󰤟", "󰤢",
                    "󰤥", "󰤨"][
                        Math.min(4, Math.floor(modelData.signalStrength / 25))]
            label: modelData.name
            detail: modelData.connected ? "connected"
                  : modelData.stateChanging ? "..."
                  : modelData.known ? "saved" : ""
            highlight: modelData.connected

            onActivated: {
                if (modelData.connected) modelData.disconnect();
                else if (modelData.known || modelData.security === WifiSecurityType.None)
                    modelData.connect();
                else
                    root.askFor = modelData;
            }
            // Right click forgets a saved network, the way nmtui's delete does.
            onSecondary: if (modelData.known) modelData.forget()
        }
    }

    // Password entry, shown only for a secured network we have no saved
    // connection for.
    property var askFor: null

    Rectangle {
        width: parent.width
        visible: !!root.askFor
        implicitHeight: 34
        radius: Theme.panelRadius
        color: Theme.raised
        border.width: 2
        border.color: psk.activeFocus ? Theme.accent : "transparent"

        TextInput {
            id: psk
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelFontSize
            echoMode: TextInput.Password
            focus: visible
            onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
            onAccepted: {
                root.askFor.connectWithPsk(text);
                root.askFor = null;
                text = "";
            }
            Keys.onEscapePressed: root.askFor = null

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: psk.text === ""
                text: "Password, then Enter"
                color: Theme.fgDim
                opacity: 0.6
                font: psk.font
            }
        }
    }
}
