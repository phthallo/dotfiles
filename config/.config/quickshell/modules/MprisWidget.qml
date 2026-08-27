import QtQuick
import Quickshell.Services.Mpris
import "root:/"

// waybar's mpris module, whose format string was
// "[   {status_icon} | {dynamic} ]" - brackets, music note, separator
// and spacing all literal characters in one monospace run.
//
// Here it is a Group of real items instead. Kept as one string it was the
// only cluster on the bar whose insides were spaced by literal space
// characters, which came to about 7px against the 20 every other item sits
// at, and it read visibly cramped beside them.
Group {
    id: root

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

    readonly property string statusIcon: playing ? "▶"
        : player?.playbackState === MprisPlaybackState.Paused ? "⏸"
        : ""

    // Gone entirely with nothing playing, matching the panel's card. A
    // paused player still counts - the widget is how you resume it - but
    // playerctld keeps a stopped, title-less player around indefinitely, so
    // "a player exists" on its own is not a signal that anything is on.
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
