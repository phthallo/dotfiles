import QtQuick
import Quickshell.Services.Mpris
import "root:/"

// waybar's mpris module: was one format string with brackets, music note,
// separator and spacing as literal characters in a monospace run. Here it's a
// Group of real items instead, spaced like the rest of the bar.
Group {
    id: root

    // Falls back to the first player that exists, so a paused Spotify still
    // shows instead of vanishing the moment you hit pause.
    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.playbackState === MprisPlaybackState.Playing)
            ?? ps[0] ?? null;
    }

    readonly property bool playing:
        player?.playbackState === MprisPlaybackState.Playing

    readonly property string statusIcon: playing ? "▶"
        : player?.playbackState === MprisPlaybackState.Paused ? "⏸"
        : ""

    // Hidden with nothing playing. A paused player still counts, but
    // playerctld keeps a stopped, title-less player around indefinitely, so
    // "a player exists" alone isn't a sign anything is on.
    visible: !!player
        && player.playbackState !== MprisPlaybackState.Stopped
        && !!player.trackTitle

    // dynamic-len: 40, dynamic-order: ["artist"]
    readonly property string dynamic: {
        const a = player?.trackArtist ?? "";
        return a.length > 40 ? a.slice(0, 40) : a;
    }

    // #mpris.playing flips the whole label, brackets included, to a filled
    // green pill.
    ink: playing ? Theme.bg : Theme.fg
    chipColor: playing ? Theme.green : "transparent"

    BarText {
        text: ""
        color: root.ink
        onLeft: () => root.player?.togglePlaying()
    }

    BarText {
        text: root.statusIcon
        color: root.ink
        onLeft: () => root.player?.togglePlaying()
    }

    // The separator and the artist only earn their place together.
    Separator {
        color: root.ink
        visible: root.dynamic !== ""
    }

    BarText {
        text: root.dynamic
        color: root.ink
        visible: root.dynamic !== ""
        onLeft: () => root.player?.togglePlaying()
    }
}
