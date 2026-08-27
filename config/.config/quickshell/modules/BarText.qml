import QtQuick
import QtQuick.Layouts
import "root:/"

// Shared look for every textual item on the bar, plus the click handling
// waybar expressed as on-click/on-click-right/on-click-middle.
Text {
    id: root

    property var onLeft: null
    property var onRight: null
    property var onMiddle: null

    // Extra width to reserve for anything an item draws outside its own text
    // - the bell's superscript count is the only user. real, not int: a 4.6px
    // count rounded down to 4 leaned half a pixel onto its glyph.
    property real extraWidth: 0

    // Fills an item with the pill treatment waybar applied via CSS classes
    // (#battery.charging, #mpris.playing, #workspaces button.active).
    property color chipColor: "transparent"
    property int chipRadius: 2

    color: Theme.fg
    font.family: Theme.fontFamily
    font.letterSpacing: Theme.letterSpacing
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    // Fills the group's height so every label centres against the same box
    // instead of its own glyph metrics.
    Layout.fillHeight: true

    // Pads the glyph's actual ink, not its font advance - in this font the
    // two barely relate ("|" paints 3px of an 8.3px advance, a Nerd Font icon
    // paints 15-19px and spills past it). Padding the advance instead left
    // icons 12px apart and digits 24px apart on screen. So: shift text right
    // by the ink's left bearing, and pad the right from contentWidth (not the
    // advance - Qt lays some icons out wider than the font reports). An empty
    // string gets no padding either, so a blank title doesn't leave a hole.
    property int pad: Theme.itemPad
    TextMetrics {
        id: metrics
        font: root.font
        text: root.text
    }
    leftPadding: text === "" ? 0 : pad - metrics.tightBoundingRect.x
    rightPadding: text === "" ? 0
        : pad + metrics.tightBoundingRect.width
          + metrics.tightBoundingRect.x - contentWidth
    Layout.preferredWidth: implicitWidth + extraWidth

    Rectangle {
        // Below the text but still inside it, so the chip tracks the label's
        // padded size without a separate layout item.
        z: -1
        anchors.fill: parent
        color: root.chipColor
        radius: root.chipRadius
        visible: root.chipColor.a > 0
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: (root.onLeft || root.onRight || root.onMiddle)
            ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: event => {
            if (event.button === Qt.LeftButton && root.onLeft)
                root.onLeft();
            else if (event.button === Qt.RightButton && root.onRight)
                root.onRight();
            else if (event.button === Qt.MiddleButton && root.onMiddle)
                root.onMiddle();
        }
    }
}
