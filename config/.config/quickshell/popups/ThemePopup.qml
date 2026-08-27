import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "root:/"

// The theme picker, replacing a wofi --dmenu spawned by theme-switcher.sh.
// This is an xdg popup in an already-running process, so it opens instantly
// and dismisses on an outside click. Applying still goes through
// theme-switcher.sh/apply-theme.sh, the same entry point a keybind uses.
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

            // Read synchronously - a few hundred bytes each, ten of them - so
            // the list doesn't pop in one name at a time.
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

            // Filled dot for the active theme, hollow for the rest.
            glyph: active ? "\uf111" : "\uf10c"
            label: pretty
            // dynamic builds its palette from a wallpaper you pick, so it
            // opens its own chooser rather than applying straight away.
            detail: fileName === "dynamic" ? "wallpaper" : ""
            highlight: active

            onActivated: {
                root.open = false;
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
