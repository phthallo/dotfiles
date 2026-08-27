import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "root:/"

// swaync's mpris widget: album art blurred to a tint behind a dark scrim,
// the art again at 64px beside two lines of text, and a centred transport
// row with the play button raised on its own disc.
Item {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.playbackState === MprisPlaybackState.Playing)
            ?? ps.find(p => p.playbackState !== MprisPlaybackState.Stopped)
            ?? null;
    }
    readonly property bool playing:
        player?.playbackState === MprisPlaybackState.Playing

    visible: true
    implicitHeight: content.implicitHeight + 10

    // border-top: 1px solid rgba(255,255,255,0.10), padding: 10px 0 0 0
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Theme.hairline
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: 10
        clip: true

        // ClippingRectangle actually clips children to the rounded shape -
        // a plain Rectangle's radius only rounds its own fill, so the blur
        // below kept poking square corners past it.
        ClippingRectangle {
            anchors.fill: parent
            radius: Theme.panelRadius
            color: Theme.bg

            // Decoded at 64px: it's going through a 34px blur at 40%
            // opacity, so a full-res decode (36MB for a 3000px cover)
            // buys nothing. Also matches the cover's sourceSize below,
            // so Qt's image cache (keyed on source+size) shares one
            // decode between them.
            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 64
                sourceSize.height: 64
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: art
                blurEnabled: true
                blur: 1.0
                blurMax: 34
                autoPaddingEnabled: false
                opacity: 0.30
                visible: art.status === Image.Ready
            }

            // scrim over the blur so the text stays readable on bright covers
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
            }
        }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 14      // .mpris-overlay padding
            anchors.rightMargin: 14
            anchors.topMargin: 12
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // No music-note fallback like swaync's - the slot just
                // collapses and the text takes the full width.
                Image {
                    id: cover
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 64
                    sourceSize.height: 64
                    asynchronous: true
                    visible: status === Image.Ready
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: root.player?.trackTitle || "Nothing playing"
                        color: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.panelFontSize * 1.05)
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.player?.trackArtist ?? ""
                        color: Qt.rgba(1, 1, 1, 0.75)
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.panelFontSize * 0.95)
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 24
                spacing: 0

                Item { Layout.fillWidth: true }

                Repeater {
                    model: [
                        { glyph: "\uf048", act: "previous" },
                        { glyph: "", act: "toggle" },
                        { glyph: "\uf051", act: "next" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool disc: modelData.act === "toggle"
                        // Named to avoid shadowing Item's own `enabled` -
                        // shadowing it here would silently drop Qt Quick's
                        // native input-blocking for disabled items.
                        readonly property bool hasPlayer: !!root.player

                        Layout.leftMargin: disc ? 14 : 18
                        Layout.rightMargin: disc ? 14 : 18
                        implicitWidth: disc ? 40 : 28
                        implicitHeight: disc ? 34 : 28
                        radius: Theme.pillRadius
                        opacity: hasPlayer ? 1 : 0.35
                        color: disc
                            ? Qt.rgba(1, 1, 1, btn.containsMouse ? 0.26 : 0.14)
                            : Qt.rgba(1, 1, 1, btn.containsMouse ? 0.16 : 0)

                        Text {
                            anchors.centerIn: parent
                            text: parent.disc
                                ? (root.playing ? "\uf04c" : "\uf04b")
                                : parent.modelData.glyph
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelFontSize
                            color: parent.disc || btn.containsMouse
                                ? "#ffffff" : Qt.rgba(1, 1, 1, 0.65)
                        }

                        MouseArea {
                            id: btn
                            anchors.fill: parent
                            hoverEnabled: parent.hasPlayer
                            cursorShape: parent.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                const p = root.player;
                                if (!p) return;
                                if (parent.modelData.act === "previous") p.previous();
                                else if (parent.modelData.act === "next") p.next();
                                else p.togglePlaying();
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
