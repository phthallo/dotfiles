import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import "root:/"
import "panels"

// swaync's control center, ordered as config.json listed its widgets:
// buttons-grid, volume, brightness, title, notifications, mpris.
Scope {
    id: root

    required property var modelData

    // A layer surface never gets a focus-out from a plain click, so "click
    // outside to close" needs an actual surface to catch it. This backdrop
    // stacks under the panel and does that.
    PanelWindow {
        screen: root.modelData
        visible: Notifications.panelOpen
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:cc-backdrop"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: Notifications.panelOpen = false
        }
    }

    PanelWindow {
        id: panel
        screen: root.modelData
        visible: Notifications.panelOpen
        onVisibleChanged: if (visible) show.restart()
        // The loader builds this window already visible, so onVisibleChanged
        // never fires for the open that caused it.
        Component.onCompleted: if (visible) show.restart()

        ParallelAnimation {
            id: show
            NumberAnimation {
                target: card; property: "opacity"
                from: 0; to: 1
                duration: Theme.openDuration; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: slide; property: "y"
                from: -Theme.openSlide; to: 0
                duration: Theme.openDuration; easing.type: Easing.OutCubic
            }
        }

        anchors.top: true
        anchors.right: true
        margins.top: Theme.gap
        margins.right: Theme.gap

        implicitWidth: Theme.panelWidth
        implicitHeight: Math.min(screen.height - 2 * Theme.gap,
                                 body.implicitHeight + 2 * Theme.panelPad)
        color: "transparent"

        // Overlay, one layer above the backdrop. Both used to sit on Top,
        // where stacking follows map order - the backdrop mapped last and
        // swallowed every click meant for the panel.
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:controlcenter"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        // Normal + zero zone floats the panel over tiled windows while still
        // respecting other surfaces' reserved zones; Ignore made it slide up
        // under the bar.
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0

        Rectangle {
            id: card
            anchors.fill: parent
            transform: Translate { id: slide }
            color: Theme.bg
            radius: Theme.panelRadius
            border.width: Theme.borderWidth
            border.color: Theme.borderActive

            ColumnLayout {
                id: body
                anchors.fill: parent
                anchors.margins: Theme.panelPad
                spacing: Theme.blockGap

                GridLayout {
                    Layout.fillWidth: true
                    columns: 5
                    columnSpacing: Theme.cardGap
                    rowSpacing: Theme.cardGap

                    GridButton {
                        glyph: "󰐥"
                        onTriggered: { Notifications.panelOpen = false; power.startDetached(); }
                    }
                    GridButton {
                        glyph: "󰑓"
                        onTriggered: { Notifications.panelOpen = false; power.startDetached(); }
                    }
                    GridButton {
                        glyph: "󰌾"
                        onTriggered: { Notifications.panelOpen = false; lock.startDetached(); }
                    }
                    GridButton {
                        glyph: "󰍃"
                        onTriggered: logout.startDetached()
                    }
                    GridButton {
                        glyph: "󰂛"
                        toggle: true
                        active: Notifications.dnd
                        onTriggered: Notifications.dnd = !Notifications.dnd
                    }

                    // These four read live off the bus rather than polling
                    // wpctl/nmcli/bluetoothctl on a timer.
                    GridButton {
                        glyph: "󰕾"
                        toggle: true
                        active: !(Pipewire.defaultAudioSink?.audio.muted ?? true)
                        onTriggered: {
                            const a = Pipewire.defaultAudioSink?.audio;
                            if (a) a.muted = !a.muted;
                        }
                    }
                    GridButton {
                        glyph: "󰍬"
                        toggle: true
                        active: !(Pipewire.defaultAudioSource?.audio.muted ?? true)
                        onTriggered: {
                            const a = Pipewire.defaultAudioSource?.audio;
                            if (a) a.muted = !a.muted;
                        }
                    }
                    GridButton {
                        glyph: "󰖩"
                        toggle: true
                        active: Networking.wifiEnabled
                        onTriggered: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                    GridButton {
                        glyph: "󰂯"
                        toggle: true
                        active: Bluetooth.defaultAdapter?.enabled ?? false
                        onTriggered: {
                            const a = Bluetooth.defaultAdapter;
                            if (a) a.enabled = !a.enabled;
                        }
                    }
                    GridButton {
                        glyph: "󰄀"
                        onTriggered: { Notifications.panelOpen = false; shot.startDetached(); }
                    }
                }

                PanelSlider {
                    glyph: "󰕾"
                    value: Pipewire.defaultAudioSink?.audio.volume ?? 0
                    onMoved: v => {
                        const a = Pipewire.defaultAudioSink?.audio;
                        if (a) a.volume = v;
                    }
                }

                PanelSlider {
                    id: brightness
                    glyph: "󰃠"
                    property real level: 0.5
                    value: level
                    // Writes go through a timer, not straight from onMoved: a
                    // drag fires onMoved once per pointer move, and each write
                    // is a shell plus brightnessctl.
                    onMoved: v => {
                        level = v;
                        brightnessWrite.restart();
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 34

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 21
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: clearLabel.implicitWidth + 28
                        implicitHeight: 26
                        radius: Theme.panelRadius
                        color: clearMouse.containsMouse ? Theme.accent : Theme.raised

                        Text {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "Clear"
                            color: clearMouse.containsMouse ? Theme.bg : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifications.dismissAll()
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.hairline
                    }
                }

                // Placeholder text is a sibling of the Flickable, not a
                // child - a child parents to the content item, which is
                // zero-high when the list is empty.
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight:
                        Math.max(200, Math.min(460, flick.contentHeight))

                    Flickable {
                        id: flick
                        anchors.fill: parent
                        contentHeight: notifList.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: notifList
                            width: parent.width
                            spacing: 2 * Theme.cardGap

                            Repeater {
                                model: Notifications.list
                                delegate: NotifCard {
                                    required property var modelData
                                    notif: modelData
                                    cardWidth: notifList.width
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: Notifications.list.length === 0
                        text: "No Notifications"
                        opacity: 0.45
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelFontSize
                    }
                }

                MprisPlayer { Layout.fillWidth: true }
            }
        }
    }

    // A PwNode's audio properties stay at their defaults until something
    // asks pipewire to bind the node.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // The one control here with no bus to listen to, so it's read once per
    // panel open rather than on a timer.
    Process {
        id: brightnessGet
        command: [Quickshell.env("HOME") + "/.config/swaync/scripts/brightness_get.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                if (isNaN(n))
                    return;
                brightness.level = n / 100;
                // Marks it as already-written so a drag away and back isn't
                // skipped as a no-op against a stale value.
                brightnessWrite.last = n;
            }
        }
    }
    Process { id: brightnessSet }

    // Restarted on every drag event; fires once the handle has settled.
    Timer {
        id: brightnessWrite
        interval: 60
        property int last: -1
        onTriggered: {
            if (brightnessSet.running) {
                restart();
                return;
            }
            const pct = Math.round(brightness.level * 100);
            if (pct === last)
                return;
            last = pct;
            brightnessSet.command = [
                Quickshell.env("HOME") + "/.config/swaync/scripts/brightness_set.sh",
                String(pct)
            ];
            brightnessSet.running = true;
        }
    }

    Connections {
        target: Notifications
        function onPanelOpenChanged() {
            if (Notifications.panelOpen)
                brightnessGet.running = true;
        }
    }

    Process {
        id: power
        command: ["sh", "-c",
            "wleave -l $HOME/.config/wlogout/layout -b 5 -T 40% -B 40% -L 5% -R 5%"]
    }
    Process { id: lock; command: ["hyprlock", "-q"] }
    Process { id: logout; command: ["hyprctl", "dispatch", "exit"] }
    Process {
        id: shot
        command: ["sh", "-c", "sleep 0.3; \"$HOME/.local/bin/screenshot\" region"]
    }
}
