pragma Singleton

import QtQuick
import Quickshell

// Turns a Wayland app id into an icon, which is guesswork more often than
// not. Nothing here can stat a file, so it hands back a ranked list and lets
// the Image walk it: each candidate that fails to load falls through to the
// next.
Singleton {
    id: root

    function iconNames(appId) {
        const names = [];
        const push = n => {
            if (n && names.indexOf(n) === -1)
                names.push(n);
        };

        const entry = DesktopEntries.heuristicLookup(appId);
        if (entry)
            push(entry.icon);

        push(appId);
        push(appId.toLowerCase());
        // org.mozilla.firefox -> firefox
        push(appId.split(".").pop().toLowerCase());

        // heuristicLookup misses a flatpak whose reversed-dns entry id has
        // nothing to do with the app id it sets on its windows, so match the
        // id against the tail of every entry: spotify -> com.spotify.Client.
        const needle = "." + appId.toLowerCase() + ".";
        for (const e of (DesktopEntries.applications?.values ?? [])) {
            const id = (e.id ?? "").toLowerCase();
            if (id.indexOf(needle) !== -1)
                push(e.icon);
        }

        return names;
    }

    function appIconCandidates(appId) {
        if (!appId)
            return [Quickshell.iconPath("application-x-executable")];

        const out = [];
        const names = iconNames(appId);

        for (const name of names) {
            // check: true returns "" on a theme miss instead of a path that
            // resolves to nothing.
            const themed = Quickshell.iconPath(name, true);
            if (themed)
                out.push(themed);
        }
        // Qt's theme lookup never checks pixmaps, which is where vscode's
        // declared icon actually lives.
        for (const name of names) {
            out.push("file:///usr/share/pixmaps/" + name + ".png");
            out.push("file:///usr/share/pixmaps/" + name + ".svg");
        }

        out.push(Quickshell.iconPath("application-x-executable"));
        return out;
    }
}
