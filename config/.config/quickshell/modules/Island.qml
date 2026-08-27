import QtQuick
import QtQuick.Layouts
import "root:/"

// One of the bar's rounded boxes.
//
// waybar drew the border with .modules-left/.modules-center/.modules-right and
// then put custom/openbracket and custom/closebracket modules INSIDE it, which
// render the literal characters "[" and "]". They are part of the look rather
// than padding, so the island draws them itself and every island gets them for
// free - matching what the stylesheet did for all four groups.
Rectangle {
    id: root

    default property alias content: inner.data
    // 0, not a gap: every module carries its own padding, the way
    // waybar's per-module `padding: 0 10px` rules did. Adding spacing
    // on top of that double-counts and the island reads as loose.
    property int spacing: 0

    color: Theme.bg
    radius: Theme.radius
    border.width: Theme.borderWidth
    border.color: Theme.borderActive

    implicitWidth: row.implicitWidth + 20   // .modules-*: padding 0 10px
    implicitHeight: Theme.islandHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Bracket { text: "[" }

        RowLayout {
            id: inner
            spacing: root.spacing
            anchors.verticalCenter: parent.verticalCenter
        }

        Bracket { text: "]" }
    }
}
