import QtQuick
import "root:/"

// waybar's custom/openbracket and custom/closebracket: a literal "[" or "]"
// with margin: 0 5px.
Text {
    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    leftPadding: 5
    rightPadding: 5
    anchors.verticalCenter: parent.verticalCenter
}
