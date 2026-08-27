import QtQuick
import "root:/"

// waybar's custom/swaync: the bell, with an unread count in superscript and a
// crossed-out variant for do-not-disturb.
//
// Left click toggled swaync's panel and right click toggled DND. Both now go
// to our own Notifications service rather than out to swaync-client.
BarText {
    id: root

    text: Notifications.dnd ? "\uF1F6" : "\uF0F3"   // bell-slash / bell
    color: Notifications.list.length > 0 && !Notifications.dnd
        ? Theme.accent : Theme.fg

    font.pixelSize: Theme.fontSize + 1   // #custom-swaync: 16px
    // The superscript sits outside the glyph, so its width has to be
    // reserved by hand or the closing bracket lands on top of it.
    extraWidth: sup.visible ? sup.implicitWidth : 0

    onLeft: () => Notifications.panelOpen = !Notifications.panelOpen
    onRight: () => Notifications.dnd = !Notifications.dnd

    // The count rides above the glyph the way waybar's <sup> did.
    Text {
        id: sup
        visible: Notifications.list.length > 0
        text: Notifications.list.length
        // Anchored to the item's right edge and inset by the same padding
        // every other item keeps clear, which lands it exactly in the
        // extraWidth reserved above - just past the bell, with a full gap
        // after it. Anchoring to parent.right without the inset put it
        // beyond the item entirely, so the reserved width became a hole to
        // its left and the count still leaned on the next item.
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.bottom: parent.verticalCenter
        color: Theme.accent
        font.family: Theme.fontFamily
        font.letterSpacing: Theme.letterSpacing
        font.pixelSize: Math.round(Theme.fontSize * 0.6)
    }
}
