pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon, replacing swaync. Only one process may own
// org.freedesktop.Notifications, so swaync must be stopped before this runs
// or notifications silently keep going to it. See README.md.
Singleton {
    id: root

    property bool panelOpen: false
    property bool dnd: false

    readonly property int maxTracked: 50

    // Everything received this session, newest first. Unlike swaync, this
    // doesn't persist across restarts.
    property list<var> list: []

    // The subset shown as floating toasts, oldest first.
    property list<var> popups: []

    // swaync's defaults, which config.json never overrode.
    function timeoutFor(notif) {
        if (notif.expireTimeout > 0)
            return notif.expireTimeout;
        switch (notif.urgency) {
        case NotificationUrgency.Critical: return 0;
        case NotificationUrgency.Low: return 5000;
        default: return 10000;
        }
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notif => {
            // tracked() keeps the object alive past this callback - without
            // it the notification is freed immediately and the list fills
            // with nulls.
            notif.tracked = true;
            // Each tracked notification holds an image buffer, so drop the
            // oldest past the cap rather than growing unbounded.
            const kept = root.list.slice(0, root.maxTracked - 1);
            for (const old of root.list.slice(root.maxTracked - 1))
                old.dismiss();
            root.list = [notif, ...kept];

            notif.closed.connect(() => {
                root.list = root.list.filter(n => n !== notif);
                root.popups = root.popups.filter(n => n !== notif);
            });

            if (!root.dnd && !root.panelOpen)
                root.popups = [...root.popups, notif];
        }
    }

    onPanelOpenChanged: if (panelOpen) popups = [];
    onDndChanged: if (dnd) popups = [];

    function expire(notif) {
        root.popups = root.popups.filter(n => n !== notif);
    }

    function dismiss(notif) {
        notif.dismiss();
    }

    function dismissAll() {
        // dismiss() fires closed, which splices the list under us, so walk a
        // copy rather than the live property.
        for (const n of [...root.list])
            n.dismiss();
        root.list = [];
        root.popups = [];
    }
}
