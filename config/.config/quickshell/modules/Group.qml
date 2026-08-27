import QtQuick
import QtQuick.Layouts
import "root:/"

// One of waybar's group/* widgets: a run of modules wrapped in the literal
// "[" and "]" that custom/openbracket and custom/closebracket rendered.
//
// Several of these can share one Island, which is what the left and right
// containers do.
//
// chipColor fills the WHOLE group, brackets included. #mpris.playing set a
// background-color on the mpris module, and its brackets came from that
// module's own format string - so the green pill swallows the brackets too
// rather than sitting behind individual labels.
//
// The chip is a sibling of the Row rather than a child of it: Qt refuses
// left/right/fill/centerIn anchors on anything inside a positioner, and
// "Row will not function" is a warning, not an error - the group silently
// collapsed to zero width and spilled out past the island border.
Item {
    id: root

    default property alias content: inner.data
    property color chipColor: "transparent"
    property color ink: Theme.fg

    implicitWidth: row.implicitWidth
    // A fixed interior height for the whole group, so the brackets and every
    // label in between are centred against the same box.
    implicitHeight: Theme.islandHeight - 2 * Theme.borderWidth

    Rectangle {
        anchors.fill: parent
        color: root.chipColor
        radius: 2                       // #mpris.playing { border-radius: 2px }
        visible: root.chipColor.a > 0
    }

    Row {
        id: row
        height: root.height
        spacing: 0

        Bracket {
            text: "["
            color: root.ink
            height: row.height
        }

        RowLayout {
            id: inner
            spacing: 0
            height: row.height
        }

        Bracket {
            text: "]"
            color: root.ink
            height: row.height
        }
    }
}
