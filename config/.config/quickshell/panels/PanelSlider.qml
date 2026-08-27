import QtQuick
import QtQuick.Layouts
import "root:/"

// A swaync slider: glyph, hairline trough, accent fill, hollow ring handle.
// value is 0..1; the owner decides what that means.
RowLayout {
    id: root

    property string glyph: ""
    property real value: 0
    signal moved(real value)

    Layout.fillWidth: true
    spacing: 12                       // margin-right on the glyph

    Text {
        Layout.preferredWidth: 18     // min-width: 18px
        text: root.glyph
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelFontSize
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.80)
        horizontalAlignment: Text.AlignHCenter
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 16

        Rectangle {                   // trough
            id: trough
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 3
            radius: Theme.pillRadius
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.22)
        }

        Rectangle {                   // highlight
            anchors.verticalCenter: parent.verticalCenter
            width: trough.width * Math.max(0, Math.min(1, root.value))
            height: 3
            radius: Theme.pillRadius
            color: Theme.accent
        }

        Rectangle {                   // handle
            x: trough.width * Math.max(0, Math.min(1, root.value)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 13
            height: 13
            radius: Theme.pillRadius
            color: Theme.bg
            border.width: 2
            border.color: drag.containsMouse || drag.pressed
                ? Theme.fg : Theme.accent
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function set(x) {
                root.moved(Math.max(0, Math.min(1, x / trough.width)));
            }
            onPressed: event => set(event.x)
            onPositionChanged: event => { if (pressed) set(event.x); }
        }
    }
}
