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

// swaync's control center, in the order config.json listed its widgets:
// buttons-grid, volume, brightness, title, notifications, mpris.
//
// Geometry from the same file: 420 wide, pinned top-right, 20px off every
// edge to match gaps_out in hyprland.conf, on the top layer with an
// exclusive zone - opening it shifts tiled windows aside exactly as swaync's
// did.
Scope {
    id: root

    required property var modelData

    // Backdrop first, so it stacks under the panel. A layer surface never
    // gets a focus-out from a plain pointer click (the compositor keeps
    // handing it the keyboard), so "click outside to close" has to be an
    // actual surface that catches the click. Both windows are ours, so there
    // is no race over which one the click lands on.
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

        // Same fade-and-settle as every popup the bar drops down; see
        // Theme.openDuration.
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
        anchors.bottom: true
        margins.top: Theme.gap
        margins.right: Theme.gap
        margins.bottom: Theme.gap

        implicitWidth: Theme.panelWidth
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:controlcenter"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusiveZone: Theme.panelWidth + Theme.gap

        // The panel is as tall as its content, top-aligned, and the rest of
        // the surface is click-through so the backdrop below can take it.
        mask: Region { item: card }

        Rectangle {
            id: card
            anchors.top: parent.top
            width: parent.width
            transform: Translate { id: slide }
            implicitHeight: Math.min(parent.height,
                                     body.implicitHeight + 2 * Theme.panelPad)
            color: Theme.bg
            radius: Theme.panelRadius
            border.width: Theme.borderWidth
            border.color: Theme.borderActive

            ColumnLayout {
                id: body
                anchors.fill: parent
                anchors.margins: Theme.panelPad
                spacing: Theme.blockGap

                // ---- buttons-grid#cc_controls, buttons-per-row: 5 ----
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

                    // The four toggles below used to shell out to wpctl,
                    // nmcli and bluetoothctl on a poll to find their state.
                    // They read it off the bus now, so the grid costs nothing
                    // while it is closed and updates the instant it changes.
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

                // ---- volume#cc_volume ----
                PanelSlider {
                    glyph: "󰕾"
                    value: Pipewire.defaultAudioSink?.audio.volume ?? 0
                    onMoved: v => {
                        const a = Pipewire.defaultAudioSink?.audio;
                        if (a) a.volume = v;
                    }
                }

                // ---- slider#cc_brightness ----
                PanelSlider {
                    id: brightness
                    glyph: "󰃠"
                    property real level: 0.5
                    value: level
                    onMoved: v => {
                        level = v;
                        brightnessSet.command = [
                            Quickshell.env("HOME") + "/.config/swaync/scripts/brightness_set.sh",
                            String(Math.round(v * 100))
                        ];
                        brightnessSet.running = true;
                    }
                }

                // ---- title#notif_title ----
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

                    Rectangle {   // border-bottom hairline under the title
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.hairline
                    }
                }

                // ---- notifications ----
                // min-height 200 / max-height 460, scrolling inside that.
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(200, Math.min(460, contentHeight))
                    contentHeight: notifList.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: notifList
                        width: parent.width
                        spacing: 2 * Theme.cardGap   // .notification-background padding: 4px 0

                        Repeater {
                            model: Notifications.list
                            delegate: NotifCard {
                                required property var modelData
                                notif: modelData
                                cardWidth: notifList.width
                            }
                        }
                    }

                    // .control-center-list-placeholder
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

                // ---- mpris ----
                MprisPlayer { Layout.fillWidth: true }
            }
        }
    }

    // A PwNode's audio properties stay at their defaults until something
    // asks pipewire to bind the node - without this the volume slider reads
    // a flat zero and the mute toggles never change state. Tracking only the
    // two default devices, so the bind cost does not scale with how many
    // streams happen to be playing.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // Backlight is the one control here with no bus to listen to, so it is
    // read once each time the panel opens rather than on a timer.
    Process {
        id: brightnessGet
        command: [Quickshell.env("HOME") + "/.config/swaync/scripts/brightness_get.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                if (!isNaN(n)) brightness.level = n / 100;
            }
        }
    }
    Process { id: brightnessSet }

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
