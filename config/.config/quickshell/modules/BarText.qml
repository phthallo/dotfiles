import QtQuick
import QtQuick.Layouts
import "root:/"

// Shared look for every textual item on the bar, plus the click handling
// waybar expressed as on-click/on-click-right/on-click-middle.
//
// chipColor gives an item the filled-pill treatment waybar applied through
// CSS classes - #battery.charging, #mpris.playing, #workspaces button.active
// all set a background-color and flipped the text to the bar background.
Text {
    id: root

    property var onLeft: null
    property var onRight: null
    property var onMiddle: null

    // Width in monospace cells. Pango lays every label out as one cell per
    // character; Qt asks the font, and for Nerd Font icons it gets back a
    // 1.0-1.15em advance instead of 0.62em, so each icon sat ~6px wider than
    // waybar's. Counting characters reproduces waybar's geometry exactly and
    // lets the icon ink overflow its cell, which is what Pango does too.
    // Array.from, not .length: Plane-15 icons are surrogate pairs.
    property int cells: Array.from(text).length

    property color chipColor: "transparent"
    property int chipRadius: 2

    color: Theme.fg
    font.family: Theme.fontFamily
    font.letterSpacing: Theme.letterSpacing
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    // Fill the group's height so every label centres against the same
    // box; without it each one centres on its own glyph metrics and
    // items with different ink heights sit at different offsets.
    Layout.fillHeight: true
    Layout.preferredWidth: cells > 0
        ? leftPadding + cells * Theme.cellWidth + rightPadding
        : implicitWidth

    Rectangle {
        // z below the text but still inside it, so the chip tracks the label's
        // size including its padding without a separate layout item.
        z: -1
        anchors.fill: parent
        color: root.chipColor
        radius: root.chipRadius
        visible: root.chipColor.a > 0
    }

    MouseArea {
        anchors.fill: parent
        // Listing every button here rather than only the ones a given item
        // uses keeps this one component usable everywhere; unbound buttons
        // fall through to a null check below.
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
