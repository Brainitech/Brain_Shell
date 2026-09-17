pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris

// Unified MPRIS media player manager.
// Single source of truth for active player across CenterContent,
// MiniPlayer, and PlayerCard. Handles filtering, auto-promotion,
// and playback control delegation.

QtObject {
    id: root

    // ── Source blocklist ──────────────────────────────────────────────────────
    readonly property var _blocked: [
        "kdeconnect",
        "gsconnect",
        "playerctld",
        "plasma-browser-integration"
    ]

    // Explicit count tracker — forces filteredPlayers to re-evaluate
    // whenever a player joins or leaves the MPRIS list.
    property int _mprisCount: Mpris.players.values.length

    readonly property var filteredPlayers: {
        var _dep = root._mprisCount
        var result = []
        var vals = Mpris.players.values
        for (var i = 0; i < vals.length; i++) {
            var id = (vals[i].identity || "").toLowerCase()
            var isBlocked = false
            for (var j = 0; j < root._blocked.length; j++) {
                if (id.indexOf(root._blocked[j]) !== -1) {
                    isBlocked = true
                    break
                }
            }
            if (!isBlocked) result.push(vals[i])
        }
        return result
    }

    // ── Selection ────────────────────────────────────────────────────────────
    property int selectedIndex: 0

    readonly property var activePlayer: filteredPlayers.length > 0
        ? filteredPlayers[Math.min(selectedIndex, filteredPlayers.length - 1)]
        : null

    onFilteredPlayersChanged: {
        // Preserve the same player object across list changes
        var old = root.activePlayer
        if (old) {
            for (var i = 0; i < root.filteredPlayers.length; i++) {
                if (root.filteredPlayers[i] === old) {
                    root.selectedIndex = i
                    return
                }
            }
        }
        // Clamp to valid range
        if (root.selectedIndex >= root.filteredPlayers.length)
            root.selectedIndex = Math.max(0, root.filteredPlayers.length - 1)
    }

    function selectPlayer(index) {
        if (index >= 0 && index < filteredPlayers.length)
            root.selectedIndex = index
    }

    // ── Auto-promote: switch to a newly playing source ───────────────────────
    property var _prevPlayingSet: ({})

    property var _promoteTimer: Timer {
        interval: 500
        running: root.filteredPlayers.length > 0
        repeat: true
        onTriggered: root._checkAutoPromote()
    }

    function _checkAutoPromote() {
        var nowPlaying = {}
        var newlyPlaying = -1
        for (var i = 0; i < filteredPlayers.length; i++) {
            if (filteredPlayers[i].playbackState === MprisPlaybackState.Playing) {
                var pid = filteredPlayers[i].identity || ("p" + i)
                nowPlaying[pid] = true
                if (!_prevPlayingSet[pid]) {
                    newlyPlaying = i
                }
            }
        }
        _prevPlayingSet = nowPlaying

        // Only auto-switch if a NEW player started playing
        // and the current selection is NOT playing
        if (newlyPlaying >= 0 && !root.isPlaying) {
            root.selectedIndex = newlyPlaying
        }
    }

    // ── Playback state ───────────────────────────────────────────────────────
    readonly property bool   isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing ?? false
    readonly property string artUrl:    activePlayer?.trackArtUrl ?? ""

    readonly property string title: {
        var t = activePlayer?.trackTitle
        return (t && t !== "") ? t : "Nothing Playing"
    }
    readonly property string artist: {
        var a = activePlayer?.trackArtists
        if (!a) return ""
        if (typeof a === "string") return a
        if (typeof a.join === "function") return a.join(", ")
        return a.toString()
    }

    readonly property real length:   activePlayer?.length   ?? 0
    readonly property real position: activePlayer?.position ?? 0

    // Interpolated position for smooth UI progress
    property real _pos: 0
    onPositionChanged: root._pos = position

    property var _posTimer: Timer {
        interval: 1000; running: root.isPlaying; repeat: true
        onTriggered: {
            if (root.length > 0)
                root._pos = Math.min(root._pos + 1, root.length)
        }
    }

    readonly property real progress: root.length > 0 ? root._pos / root.length : 0

    function _fmt(sec) {
        var s = Math.floor(sec)
        return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60)
    }

    // ── Playback controls ────────────────────────────────────────────────────
    readonly property bool canToggle: activePlayer?.canTogglePlaying ?? false
    readonly property bool canNext:   activePlayer?.canGoNext        ?? false
    readonly property bool canPrev:   activePlayer?.canGoPrevious    ?? false
    readonly property bool canSeek:   activePlayer?.canSeek          ?? false

    function toggle() {
        if (activePlayer && canToggle)
            activePlayer.isPlaying = !activePlayer.isPlaying
    }
    function next() {
        if (activePlayer && activePlayer.canGoNext) activePlayer.next()
    }

    function raisePlayer() {
        if (!activePlayer) return;
        // Native MPRIS Raise
        // (Note: Players like YouTube Music may report canRaise = false and ignore this. 
        // WM-specific overrides to force focus will be handled by the WM Adapter after V0.2.0)
        if (typeof activePlayer.raise === "function" && activePlayer.canRaise) {
            activePlayer.raise();
        }
    }
    function prev() {
        if (activePlayer && canPrev)
            activePlayer.previous()
    }
    function seek(fraction) {
        if (activePlayer && canSeek && length > 0) {
            var pos = fraction * length
            activePlayer.position = pos
            root._pos = pos
        }
    }

    // ── Player identity helpers ──────────────────────────────────────────────
    function playerIcon(player) {
        if (!player) return "♪"
        var id = (player.identity || "").toLowerCase()
        if (id.indexOf("spotify")  !== -1) return "󰓇"
        if (id.indexOf("firefox")  !== -1) return "󰈹"
        if (id.indexOf("chromium") !== -1) return "󰊯"
        if (id.indexOf("chrome")   !== -1) return "󰊯"
        if (id.indexOf("brave")    !== -1) return "󰴕"
        if (id.indexOf("youtube")  !== -1) return "󰗃"
        if (id.indexOf("edge")     !== -1) return "󰇩"
        if (id.indexOf("opera")    !== -1) return ""
        if (id.indexOf("vivaldi")  !== -1) return ""
        if (id.indexOf("vlc")      !== -1) return "󰕼"
        if (id.indexOf("mpv")      !== -1) return ""
        return "♪"
    }

    function playerLabel(player) {
        if (!player) return "—"
        var id = (player.identity || "").toLowerCase()
        if (id.indexOf("spotify")  !== -1) return "Spotify"
        if (id.indexOf("firefox")  !== -1) return "Firefox"
        if (id.indexOf("chromium") !== -1) return "Chromium"
        if (id.indexOf("chrome")   !== -1) return "Chrome"
        if (id.indexOf("brave")    !== -1) return "Brave"
        if (id.indexOf("youtube")  !== -1) return "YouTube"
        if (id.indexOf("edge")     !== -1) return "Edge"
        if (id.indexOf("opera")    !== -1) return "Opera"
        if (id.indexOf("vivaldi")  !== -1) return "Vivaldi"
        if (id.indexOf("vlc")      !== -1) return "VLC"
        if (id.indexOf("mpv")      !== -1) return "mpv"
        return player.identity || "Player"
    }

    // ── Focus redirect: bring player's window to front ───────────────────────
    property var _focusProc: Process {
        command: ["hyprctl", "dispatch", "focusurgentorlast", ""]
        running: false
    }

    function focusPlayer() {
        if (!activePlayer) return
        _focusProc.running = false
        _focusProc.running = true
    }

    // ── Global "any playing" check (for CavaService gating) ──────────────────
    readonly property bool anyPlaying: {
        for (var i = 0; i < filteredPlayers.length; i++) {
            if (filteredPlayers[i].playbackState === MprisPlaybackState.Playing) return true
        }
        return false
    }
}
