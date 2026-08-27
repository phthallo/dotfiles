import QtQuick
import QtQuick.Layouts

// One of the bar's rounded boxes.
//
// waybar drew these with .modules-left/.modules-center/.modules-right, plus
// custom/openbracket and custom/closebracket modules that literally rendered
// the characters "[" and "]" as padding. Here the box is a real container, so
// the brackets are gone and the spacing is a property rather than a glyph.
Rectangle {
    id: root

    default property alias content: layout.data
    property int spacing: 10

    color: Theme.bg
    radius: Theme.radius
    border.width: Theme.borderWidth
    // waybar used rgba(184,187,38,0.8) - a hardcoded gruvbox green at 80%.
    // The theme's own active border colour is the honest equivalent.
    border.color: Theme.borderActive

    implicitWidth: layout.implicitWidth + Theme.gap
    implicitHeight: Theme.barHeight

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: root.spacing
    }
}
