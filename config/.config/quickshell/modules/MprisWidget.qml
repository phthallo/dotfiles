import QtQuick
import Quickshell.Services.Mpris
import "root:/"

// waybar's mpris module: "[ ♪ {status} | {artist} ]", 40 chars of dynamic
// text. The brackets were part of its format string, so it is a Group - it
// shares the left island's background with the utilities group and the
// workspace buttons rather than being a box of its own.
Group {
    id: root
    visible: !!player

    // The first player actually playing, falling back to the first that
    // exists - so a paused Spotify still shows rather than the widget
    // vanishing the moment you hit pause.
    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.playbackState === MprisPlaybackState.Playing)
            ?? ps[0] ?? null;
    }

    readonly property bool playing:
        player?.playbackState === MprisPlaybackState.Playing

    // #mpris.playing flipped the whole widget to a filled green pill.
    readonly property color chip: playing ? Theme.green : "transparent"
    readonly property color ink: playing ? Theme.bg : Theme.fg

    BarText {
        text: "♪"
        color: root.ink
        chipColor: root.chip
        leftPadding: 9
    }

    BarText {
        text: !root.player ? ""
            : root.playing ? "▶"
            : root.player.playbackState === MprisPlaybackState.Paused ? "⏸"
            : "■"
        color: root.ink
        chipColor: root.chip
        leftPadding: 6
        rightPadding: 6
        onLeft: () => root.player?.togglePlaying()
    }

    BarText {
        text: "|"
        color: root.playing ? Theme.bg : Theme.fgDim
        chipColor: root.chip
    }

    BarText {
        readonly property string artist: root.player?.trackArtist ?? ""
        text: artist.length > 40 ? artist.slice(0, 40) + "…" : artist
        color: root.playing ? Theme.bg : Theme.fgDim
        chipColor: root.chip
        leftPadding: 6
        rightPadding: 9
    }
}
