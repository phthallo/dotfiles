import QtQuick
import QtQuick.Layouts
import "root:/"

// One cell of swaync's buttons-grid. Three weights, as the stylesheet had
// them: a plain action sits at 0.80 alpha, a toggle that is off drops to 0.45
// behind a faint ring, and a toggle that is on is solid accent.
Rectangle {
    id: root

    property string glyph: ""
    property bool toggle: false
    property bool active: false
    signal triggered()

    Layout.fillWidth: true
    implicitHeight: 46            // padding: 13px 0 around a 16px glyph
    radius: Theme.panelRadius
    color: root.toggle && root.active
        ? (mouse.containsMouse ? Theme.shade(Theme.accent, 1.12) : Theme.accent)
        : (mouse.containsMouse ? Theme.raisedHover : Theme.raised)

    // box-shadow: inset 0 0 0 1px alpha(@cc_fg, 0.12) on an off toggle.
    border.width: root.toggle && !root.active ? 1 : 0
    border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b,
                          mouse.containsMouse ? 0.25 : 0.12)

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: Theme.fontFamily
        font.pixelSize: 16
        color: root.toggle && root.active
            ? Theme.bg
            : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b,
                      mouse.containsMouse ? (root.toggle ? 0.85 : 1.0)
                                          : (root.toggle ? 0.45 : 0.80))
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
