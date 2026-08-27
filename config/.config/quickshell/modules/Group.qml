import QtQuick
import QtQuick.Layouts
import "root:/"

// One of waybar's group/* widgets: a run of modules wrapped in the literal
// "[" and "]" that custom/openbracket and custom/closebracket rendered.
//
// Several of these can share one Island, which is exactly what the left and
// right containers did.
Row {
    id: root

    default property alias content: inner.data

    spacing: 0

    Bracket { text: "[" }

    RowLayout {
        id: inner
        spacing: 0
        anchors.verticalCenter: parent.verticalCenter
    }

    Bracket { text: "]" }
}
