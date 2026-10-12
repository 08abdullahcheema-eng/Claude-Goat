pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The music player the bar shows: the one that is playing, else the first one.
Singleton {
    id: root
    readonly property var players: Mpris.players.values
    readonly property var player: {
        let first = null;
        for (const p of players) {
            if (!p) continue;
            if (p.isPlaying) return p;
            if (!first) first = p;
        }
        return first;
    }
    readonly property bool active: Theme.demo || (player !== null && title !== "")
    readonly property bool playing: Theme.demo ? true : (player?.isPlaying ?? false)
    readonly property string title: Theme.demo ? "Midnight City" : (player?.trackTitle ?? "")
    readonly property string artist: Theme.demo ? "M83" : (player?.trackArtist ?? "")
    readonly property string art: Theme.demo ? "" : (player?.trackArtUrl ?? "")
    readonly property real length: Theme.demo ? 243 : (player?.length ?? 0)
    property real position: Theme.demo ? 161 : 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    function fmt(sec) { const s = Math.max(0, Math.floor(sec)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }
    function toggle() { if (player && player.canTogglePlaying) player.togglePlaying(); }
    function next() { if (player && player.canGoNext) player.next(); }
    function previous() { if (player && player.canGoPrevious) player.previous(); }

    // MPRIS does not push the position, so read it once a second while something plays
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: !Theme.demo && root.player !== null
        onTriggered: root.position = root.player?.positionSupported ? root.player.position : 0
    }
}
