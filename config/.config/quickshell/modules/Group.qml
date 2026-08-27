import QtQuick
import QtQuick.Layouts
import "root:/"

// One of waybar's group/* widgets: a run of modules wrapped in literal "[" and
// "]" brackets. Several can share one Island (the left and right containers
// do).
//
// chipColor fills the whole group, brackets included, matching how
// #mpris.playing's background-color swallowed its own module's brackets too.
//
// The chip is a sibling of the Row, not a child - Qt silently ignores
// fill/anchor rules on children of a positioner ("Row will not function" is
// only a warning), which collapsed the group to zero width.
Item {
    id: root

    default property alias content: inner.data
    property color chipColor: "transparent"
    property color ink: Theme.fg

    implicitWidth: row.implicitWidth
    // Fixed interior height, so the brackets and every label centre against
    // the same box.
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
