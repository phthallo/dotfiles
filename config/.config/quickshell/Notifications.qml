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

    // The subset currently shown as floating toasts, oldest first so the
    // stack grows downward the way swaync's did.
    property list<var> popups: []

    // swaync's defaults, which config.json never overrode: normal 10s, low
    // 5s, critical stays until it is clicked away.
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

        // Advertised capabilities. Claiming a capability the UI does not
        // implement means senders format for something that never renders,
        // so these track what the cards actually draw.
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notif => {
            // tracked() keeps the object alive past this callback - without
            // it the notification is freed as soon as the handler returns and
            // the list fills with nulls.
            notif.tracked = true;
            // An app stuck in a loop can push notifications faster than
            // anyone clears them, and every tracked one holds an image
            // buffer; drop the oldest past a cap rather than growing until
            // the shell is swapping.
            const kept = root.list.slice(0, 99);
            for (const old of root.list.slice(99))
                old.dismiss();
            root.list = [notif, ...kept];

            notif.closed.connect(() => {
                root.list = root.list.filter(n => n !== notif);
                root.popups = root.popups.filter(n => n !== notif);
            });

            // Do not disturb still records the notification, it just does not
            // pop it up - so the count stays honest and you can read what you
            // missed when you turn DND off.
            if (!root.dnd)
                root.popups = [...root.popups, notif];
        }
    }

    // swaync hid the toasts while the control center was open - anything
    // that would have popped up is already visible in the list behind it.
    onPanelOpenChanged: if (panelOpen) popups = [];
    // Turning DND on should silence what is already on screen too, otherwise
    // the toggle only applies to the next notification.
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
