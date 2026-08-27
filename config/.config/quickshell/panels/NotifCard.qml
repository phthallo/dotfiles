import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "root:/"

// One notification, drawn the same in the floating stack and in the panel -
// swaync styled both from one ruleset and the two only differed in surface
// colour, which both resolved to shade(@cc_bg, 1.08) anyway.
Rectangle {
    id: root

    required property var notif
    // The panel wants the card to fill the gutter; a popup sizes the window.
    property int cardWidth: Theme.panelWidth - 2 * Theme.panelPad

    signal closed()

    width: cardWidth
    implicitHeight: body.implicitHeight + 8   // .notification padding: 4px 10px
    color: Theme.card
    radius: Theme.panelRadius

    // Clicking the card invokes the notification's default action, which is
    // what launches the app that sent it. Notifications without one just get
    // dismissed, the same as swaync.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            const def = root.notif.actions.find(a => a.identifier === "default");
            if (def)
                def.invoke();
            else
                root.notif.dismiss();
            root.closed();
        }
    }

    ColumnLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 4
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // --mpris-album-art-icon-size was 64; notification images are
            // smaller than that in swaync's layout - they ride beside two
            // lines of text rather than under them.
            Image {
                visible: source != ""
                source: root.notif.image !== "" ? root.notif.image
                    : root.notif.appIcon !== "" ? root.notif.appIcon : ""
                sourceSize.width: 48
                sourceSize.height: 48
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: root.notif.summary
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelFontSize
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    // bodyMarkupSupported is advertised, so the body arrives
                    // with Pango-style markup in it; StyledText understands
                    // the same subset and drops what it does not.
                    text: root.notif.body
                    textFormat: Text.StyledText
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelFontSize
                    wrapMode: Text.Wrap
                    maximumLineCount: 6
                    elide: Text.ElideRight
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: root.notif.appName
                    color: Theme.fgDim
                    opacity: 0.7
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelFontSize - 3
                    elide: Text.ElideRight
                }
            }
        }

        // Everything except the default action, which the card body already
        // carries - drawing it as a button too would offer the same thing
        // twice.
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            spacing: Theme.cardGap
            visible: children.length > 1

            Repeater {
                model: root.notif.actions.filter(a => a.identifier !== "default")
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 26
                    color: act.containsMouse ? Theme.accent : Theme.raised
                    radius: Theme.panelRadius
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: act.containsMouse ? Theme.bg : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelFontSize - 1
                    }
                    MouseArea {
                        id: act
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            parent.modelData.invoke();
                            root.closed();
                        }
                    }
                }
            }
        }
    }

    // .close-button: accent disc, panel-coloured glyph, nudged out over the
    // card's corner by translate(6px, -2px).
    Rectangle {
        width: 18
        height: 18
        radius: Theme.pillRadius
        color: Theme.accent
        visible: hover.containsMouse || close.containsMouse
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -6
        anchors.topMargin: -2

        Text {
            anchors.centerIn: parent
            text: "×"
            color: Theme.bg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelFontSize
        }

        MouseArea {
            id: close
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.notif.dismiss();
                root.closed();
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        // Sits under the click handler above; only there to keep the close
        // button visible while the pointer is anywhere on the card.
        z: -1
    }
}
