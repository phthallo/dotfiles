import QtQuick
import "root:/"

// waybar's custom/split module: a literal "|" between items inside an island.
Text {
    text: "|"
    color: Theme.fgDim
    font.family: Theme.fontFamily
    font.letterSpacing: Theme.letterSpacing
    font.pixelSize: Theme.fontSize
}
