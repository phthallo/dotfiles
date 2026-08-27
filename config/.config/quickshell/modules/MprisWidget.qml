import QtQuick
import Quickshell.Services.Mpris
import "root:/"

// waybar's mpris module: "[ ♪ ▶ | artist ]", 40 chars of dynamic text.
// The brackets were part of the format string there; here the island draws
// them, so only the contents live in this file.
Row {
    id: root
    spacing: 8
    visible: !!player

    // The first player that is actually playing, falling back to the first
    // that exists at all - so a paused Spotify still shows rather than the
    // widget vanishing the moment you hit pause.
    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.playbackState === MprisPlaybackState.Playing)
            ?? ps[0] ?? null;
    }

    BarText {
        text: "♪"
        color: Theme.accent
    }

    BarText {
        text: !root.player ? ""
            : root.player.playbackState === MprisPlaybackState.Playing ? "▶"
            : root.player.playbackState === MprisPlaybackState.Paused ? "⏸"
            : ""
        onLeft: () => root.player?.togglePlaying()
    }

    Separator {}

    BarText {
        readonly property string artist: root.player?.trackArtist ?? ""
        text: artist.length > 40 ? artist.slice(0, 40) + "…" : artist
        color: Theme.fgDim
    }
}
