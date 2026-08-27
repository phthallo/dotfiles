import QtQuick
import QtQuick.Layouts
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

    // Extra width to reserve beyond the label itself, for anything an item
    // draws outside its own text. The bell's superscript count is the only
    // one; without it the group's closing bracket sits on top of the count.
    property int extraWidth: 0

    property color chipColor: "transparent"
    property int chipRadius: 2

    color: Theme.fg
    font.family: Theme.fontFamily
    font.letterSpacing: Theme.letterSpacing
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    // Fill the group's height so every label centres against the same
    // box; without it each one centres on its own glyph metrics and
    // items with different ink heights sit at different offsets.
    Layout.fillHeight: true
    // Every item reserves exactly `pad` of clear space on each side of the
    // ink it actually paints, so one padding value produces one gap right
    // across the bar.
    //
    // Padding the advance instead does not, because in this font the advance
    // and the ink are barely related: every glyph advances 8.3px, while "|"
    // paints 3px of it and a Nerd Font icon paints 15-19px, spilling several
    // pixels out either side. Padding those equally left a run of icons 12px
    // apart on screen and a run of digits 24px apart. (waybar had it worse
    // still - it laid each label out in one monospace cell per character,
    // which put a 19px icon in a 9px box.)
    //
    // So the padding absorbs the difference: shift the text right by the
    // ink's left bearing, and make up the rest on the right. The width that
    // falls out is pad + ink + pad, which is what implicitWidth needs to be
    // in a plain Row as well as in a RowLayout.
    //
    // The right side subtracts contentWidth and not the advance, because for
    // the icons those two disagree - Qt lays a 15px icon out 14.3px wide
    // while the font still calls its advance 8.3 - and it is contentWidth
    // that implicitWidth is actually built from.
    property int pad: Theme.itemPad
    TextMetrics {
        id: metrics
        font: root.font
        text: root.text
    }
    leftPadding: pad - metrics.tightBoundingRect.x
    rightPadding: pad + metrics.tightBoundingRect.width
                + metrics.tightBoundingRect.x - contentWidth
    Layout.preferredWidth: implicitWidth + extraWidth

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
