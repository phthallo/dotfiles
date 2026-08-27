import QtQuick
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

    property color chipColor: "transparent"
    property int chipRadius: 2

    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter

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
