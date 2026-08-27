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
    leftPadding: 5
    rightPadding: 10

    onLeft: () => Notifications.panelOpen = !Notifications.panelOpen
    onRight: () => Notifications.dnd = !Notifications.dnd

    // The count rides above the glyph the way waybar's <sup> did.
    Text {
        visible: Notifications.list.length > 0
        text: Notifications.list.length
        anchors.left: parent.right
        anchors.bottom: parent.verticalCenter
        color: Theme.accent
        font.family: Theme.fontFamily
    font.letterSpacing: Theme.letterSpacing
        font.pixelSize: Math.round(Theme.fontSize * 0.6)
    }
}
