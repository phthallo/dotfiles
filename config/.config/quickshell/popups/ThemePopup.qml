import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "root:/"

// The theme picker, which used to be a wofi --dmenu spawned by
// theme-switcher.sh. wofi cold-starts on every open and, as a layer surface,
// could only be dismissed by the close_on_focus_loss hack; this is an xdg
// popup in a process that is already running, so it appears instantly and a
// click anywhere outside closes it.
//
// Applying still goes through theme-switcher.sh: apply-theme.sh restyles
// kitty, hyprlock, starship and the rest in one pass, and the script is the
// same entry point a keybind or a terminal uses.
PopupShell {
    id: root

    contentWidth: 340

    readonly property string base: Quickshell.env("HOME") + "/.config/theme-switcher"
    readonly property string script:
        Quickshell.env("HOME") + "/.config/waybar/scripts/theme-switcher.sh"

    // apply-theme.sh writes this, so the dot follows a switch made anywhere -
    // a keybind, a terminal, or this list.
    FileView {
        id: state
        path: root.base + "/current-theme.json"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string current: {
        try {
            return JSON.parse(state.text() || "{}").theme ?? "";
        } catch (e) {
            return "";
        }
    }

    Text {
        text: "Theme"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 17
        font.weight: Font.Bold
        bottomPadding: 6
    }

    Repeater {
        model: FolderListModel {
            folder: "file://" + root.base + "/themes"
            showDirs: true
            showFiles: false
            showDotAndDotDot: false
            sortField: FolderListModel.Name
        }

        delegate: PopupRow {
            id: row
            required property string fileName

            readonly property bool active: fileName === root.current

            // theme.json is a few hundred bytes and there are ten of them, so
            // they are read synchronously rather than making the list pop in
            // one name at a time as the reads land.
            FileView {
                id: meta
                path: root.base + "/themes/" + row.fileName + "/theme.json"
                blockLoading: true
            }
            readonly property string pretty: {
                try {
                    return JSON.parse(meta.text() || "{}").name || row.fileName;
                } catch (e) {
                    return row.fileName;
                }
            }

            // \uf111 filled dot for the active theme, \uf10c hollow for the
            // rest - the same "this one is on" marker the shell script
            // drew with a bullet.
            glyph: active ? "\uf111" : "\uf10c"
            label: pretty
            // dynamic builds its palette from a wallpaper you pick, so it
            // opens its own chooser rather than applying straight away.
            detail: fileName === "dynamic" ? "wallpaper" : ""
            highlight: active

            onActivated: {
                root.visible = false;
                if (!active)
                    root.apply(fileName);
            }
        }
    }

    function apply(theme) {
        proc.command = [root.script, theme];
        proc.running = true;
    }

    Process { id: proc }
}
