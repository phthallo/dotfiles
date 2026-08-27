import QtQuick
import Quickshell.Services.Mpris
import "root:/"

// waybar's mpris module is a SINGLE label whose format string is
// "[ \uf001  {status_icon} | {dynamic} ]" - the brackets, the music note and
// the spacing between them are literal characters in one monospace run, not
// separate widgets. Building it out of several BarTexts put Qt's own spacing
// between them and read wider than waybar's.
BarText {
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

    // \uf04d is the stop glyph: with nothing playing the widget stays put
    // and reads as stopped, rather than appearing and disappearing and
    // shifting everything beside it every time a player comes and goes.
    readonly property string statusIcon: !player ? "\uf04d"
        : playing ? "▶"
        : player.playbackState === MprisPlaybackState.Paused ? "⏸"
        : "\uf04d"

    // dynamic-len: 40, dynamic-order: ["artist"]
    readonly property string dynamic: {
        const a = player?.trackArtist ?? "";
        return a.length > 40 ? a.slice(0, 40) : a;
    }

    // The separator only earns its place when there is an artist after it.
    text: "[ \uf001  " + statusIcon + (dynamic ? " | " + dynamic : "") + " ]"

    // #mpris.playing flips the whole label to a filled green pill.
    color: playing ? Theme.bg : player ? Theme.fg : Theme.fgDim
    chipColor: playing ? Theme.green : "transparent"
    chipRadius: 2
    leftPadding: 9
    rightPadding: 9

    onLeft: () => root.player?.togglePlaying()
}
