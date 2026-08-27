import QtQuick

// Shared look for every textual item on the bar, plus the click handling
// waybar expressed as on-click/on-click-right/on-click-middle.
Text {
    id: root

    property var onLeft: null
    property var onRight: null
    property var onMiddle: null

    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter

    MouseArea {
        anchors.fill: parent
        // Listing every button here rather than only the ones a given item
        // uses keeps this one component usable everywhere; unbound buttons
        // fall through to a null check below.
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
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
