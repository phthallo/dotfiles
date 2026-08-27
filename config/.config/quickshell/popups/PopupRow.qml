import QtQuick
import "root:/"

// One selectable line in a dropdown: glyph, label, trailing detail. Same card
// surface and hover as the control center's grid buttons.
Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property string detail: ""
    property bool highlight: false
    signal activated()
    signal secondary()

    width: parent ? parent.width : 0
    implicitHeight: 34
    radius: Theme.panelRadius
    color: mouse.containsMouse ? Theme.raisedHover
         : root.highlight ? Theme.raised : "transparent"

    Text {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        color: root.highlight ? Theme.accent : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelFontSize
    }

    Text {
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: detailText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelFontSize
        font.weight: root.highlight ? Font.Bold : Font.Normal
        elide: Text.ElideRight
    }

    Text {
        id: detailText
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.detail
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelFontSize - 2
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) root.secondary();
            else root.activated();
        }
    }
}
