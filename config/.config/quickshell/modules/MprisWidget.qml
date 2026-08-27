import QtQuick
import Quickshell.Services.Mpris
import "root:/"

// waybar's mpris module: "[ ♪ {status} | {artist} ]", 40 chars of dynamic
// text. It sat between the left island and the centre one as a bare module
// with its own brackets in the format string, so it carries its own here
// rather than being wrapped in an Island.
Row {
    id: root
    spacing: 0
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

    Bracket { text: "[" }

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

    Bracket { text: "]" }
}
