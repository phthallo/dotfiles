pragma Singleton

import QtQuick
import Quickshell

// Turning a Wayland app id into an icon, which is guesswork more often than
// not. Every branch below is a real case on this machine:
//
//   kitty                 id is the icon name, the easy case
//   org.mozilla.firefox   entry declares Icon=firefox
//   code                  entry declares Icon=vscode, which lives in
//                         /usr/share/pixmaps and not in any icon theme
//   spotify               a flatpak, whose entry id is com.spotify.Client
//
// Nothing here can stat a file, so instead of picking one answer it hands
// back the whole ranked list and lets the Image walk it: each candidate that
// fails to load falls through to the next one.
Singleton {
    id: root

    // Icon names, best guess first.
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

    // Sources for an Image, in the order it should try them.
    function appIconCandidates(appId) {
        if (!appId)
            return [Quickshell.iconPath("application-x-executable")];

        const out = [];
        const names = iconNames(appId);

        for (const name of names) {
            // check: true returns "" on a theme miss rather than a path that
            // resolves to nothing, so a miss falls through instead of ending
            // the walk on a broken image.
            const themed = Quickshell.iconPath(name, true);
            if (themed)
                out.push(themed);
        }
        // Qt's theme lookup never looks in pixmaps, which is where the icon
        // vscode.desktop asks for actually lives.
        for (const name of names) {
            out.push("file:///usr/share/pixmaps/" + name + ".png");
            out.push("file:///usr/share/pixmaps/" + name + ".svg");
        }

        // A blank source leaves a hole in the dock, which reads as a
        // rendering bug rather than a missing icon.
        out.push(Quickshell.iconPath("application-x-executable"));
        return out;
    }
}
