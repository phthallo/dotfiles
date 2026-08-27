pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification daemon, replacing swaync.
//
// Only one process on the session may own org.freedesktop.Notifications, so
// swaync MUST be stopped before this runs or the server never binds and
// notifications silently keep going to swaync. See README.md.
Singleton {
    id: root

    property bool panelOpen: false
    property bool dnd: false

    // Everything received this session, newest first. swaync persisted its
    // list across restarts; this does not - a shell reload starts with an
    // empty tray, which is a real behaviour difference and the main thing to
    // check before dropping swaync for good.
    property list<var> list: []

    NotificationServer {
        id: server

        // Advertised capabilities. Claiming a capability the UI does not
        // implement means senders format for something that never renders,
        // so these track Panel.qml exactly.
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notif => {
            // tracked() keeps the object alive past this callback - without
            // it the notification is freed as soon as the handler returns and
            // the list fills with nulls.
            notif.tracked = true;
            root.list = [notif, ...root.list];

            notif.closed.connect(() => {
                root.list = root.list.filter(n => n !== notif);
            });

            // Do not disturb still records the notification, it just does not
            // pop it up - so the count stays honest and you can read what you
            // missed when you turn DND off.
            if (!root.dnd)
                popups.push(notif);
        }
    }

    property list<var> popups: []

    function dismissAll() {
        for (const n of root.list)
            n.dismiss();
        root.list = [];
    }
}
