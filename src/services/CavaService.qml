pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// Shared cava process for audio visualization.
// Lifecycle-gated: only runs when audio is playing AND at least
// one consumer is visible (notch music carousel, dashboard, or miniPlayer).

QtObject {
    id: root

    readonly property int barCount: 32

    property var bars: (function() {
        var a = []; for (var i = 0; i < 32; i++) a.push(0); return a
    })()

    property bool audioActive: false

    property var _silenceTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: root.audioActive = false
    }

    // ── Lifecycle gate ───────────────────────────────────────────────────────
    // Consumers set these booleans to signal they need cava data.
    property bool notchMusicVisible: false
    property bool dashboardVisible: false
    property bool miniPlayerVisible: false

    readonly property bool _anyConsumerVisible:
        notchMusicVisible || dashboardVisible || miniPlayerVisible

    // 5s grace period after last consumer closes to prevent flicker
    property bool _recentlyActive: false
    property var _graceTimer: Timer {
        interval: 5000
        repeat: false
        onTriggered: root._recentlyActive = false
    }

    on_AnyConsumerVisibleChanged: {
        if (_anyConsumerVisible) {
            _graceTimer.stop()
            _recentlyActive = true
        } else {
            _graceTimer.restart()
        }
    }

    readonly property bool shouldRun:
        (MediaService.anyPlaying || root.audioActive) && (_anyConsumerVisible || _recentlyActive)

    // Zero-out bars when stopping to prevent stale visualization
    onShouldRunChanged: {
        if (!shouldRun) {
            var zeroes = []
            for (var i = 0; i < barCount; i++) zeroes.push(0)
            root.bars = zeroes
            root.audioActive = false
        }
    }

    function mapPipewireSource(identity) {
        if (!identity) return "auto"
        var id = identity.toLowerCase()
        if (id.indexOf("spotify") !== -1) return "Spotify"
        if (id.indexOf("firefox") !== -1) return "Firefox"
        if (id.indexOf("chromium") !== -1) return "Chromium"
        if (id.indexOf("chrome") !== -1) return "Google Chrome"
        if (id.indexOf("brave") !== -1) return "Brave"
        if (id.indexOf("youtube") !== -1) return "YouTube Music Desktop App"
        if (id.indexOf("vlc") !== -1) return "vlc"
        if (id.indexOf("mpv") !== -1) return "mpv"
        return identity.replace(/'/g, "").replace(/"/g, "")
    }

    property string activeSource: MediaService.activePlayer ? mapPipewireSource(MediaService.activePlayer.identity) : "auto"

    property var _restartTimer: Timer {
        interval: 50
        repeat: false
        onTriggered: {
            if (root.shouldRun) _proc.running = true
        }
    }

    onActiveSourceChanged: {
        if (_proc.running) {
            _proc.running = false
            _restartTimer.restart()
        }
    }

    property var _proc: Process {
        command: [
            "bash", "-c",
            "mkdir -p /tmp/brain_shell && " +
            "printf '[general]\\nbars = 32\\nframerate = 30\\nnoise_reduction = 77\\n\\n" +
            "[input]\\nmethod = pipewire\\nsource = " + root.activeSource + "\\n\\n" +
            "[output]\\nmethod = raw\\nraw_target = /dev/stdout\\n" +
            "data_format = ascii\\nascii_max_range = 100\\n" +
            "bar_delimiter = 59\\nframe_delimiter = 10\\n' " +
            "> /tmp/brain_shell/cava_shared.ini && " +
            "exec cava -p /tmp/brain_shell/cava_shared.ini 2>/dev/null"
        ]
        running: root.shouldRun
        stdout: SplitParser {
            onRead: function(line) {
                var t = line.trim()
                if (t === "") return
                if (t.endsWith(";")) t = t.slice(0, -1)
                var parts = t.split(";")
                if (parts.length !== root.barCount) return
                var arr = []
                var hasSound = false
                for (var i = 0; i < parts.length; i++) {
                    var v = parseInt(parts[i]) || 0
                    if (v > 0) hasSound = true
                    arr.push(v)
                }
                if (hasSound) {
                    root.audioActive = true
                    root._silenceTimer.restart()
                }
                root.bars = arr
            }
        }
    }
}
