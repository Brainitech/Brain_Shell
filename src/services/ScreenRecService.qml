pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// ScreenRecService — owns all screen recording state.
//
// Audio routing (fixed):
//   none        → no -a flag; launch directly
//   mic only    → pactl get-default-source → pass directly to wf-recorder
//   system only → BrainShellMixer null sink + loopback from sink.monitor
//   both        → BrainShellMixer null sink + loopback from sink.monitor
//                 + loopback from default source (mic)
//
// The null sink is torn down after every recording (saved or discarded).
// Notifications are sent via notify-send with action buttons (requires
// libnotify ≥ 0.8 and a daemon that supports actions, e.g. dunst/mako).

QtObject {
    id: root

    // ── Persisted options ─────────────────────────────────────────────────────
    property string captureTarget: "screen"
    property bool   audioMic:      false
    property bool   audioSystem:   false

    // ── Display helpers ───────────────────────────────────────────────────────
    readonly property var _captureIcons:  ({ screen: "󰍹", window: "󱂬", region: "󰩭" })
    readonly property var _captureLabels: ({ screen: "Screen", window: "Window", region: "Region" })
    readonly property string captureIcon:  _captureIcons[captureTarget]  ?? "󰍹"
    readonly property string captureLabel: _captureLabels[captureTarget] ?? "Screen"

    readonly property string audioLabel: {
        if (audioMic && audioSystem) return "Mic + Sys"
        if (audioMic)                return "Mic"
        if (audioSystem)             return "Sys"
        return "Non"
    }

    // ── Strip hover (open = "capture" | "audio" | "") ─────────────────────────
    property string openStrip: ""
    property real popupTargetX: 0
    property real popupTargetWidth: 0

    property var _stripTimer: Timer {
        interval: 280
        onTriggered: root.openStrip = ""
    }
    function keepStripOpen()      { _stripTimer.stop()    }
    function scheduleStripClose() { _stripTimer.restart() }

    // ── Recording state ───────────────────────────────────────────────────────
    property bool   recording:      false
    property int    elapsed:        0
    property string _currentFile:   ""   // tracked so discard can delete it
    property bool   _discarding:    false // true when discardRecording() was called
    property bool   _usingNullSink: false // true while BrainShellMixer is active

    readonly property string elapsedDisplay: {
        var m = Math.floor(elapsed / 60)
        var s = elapsed % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    property var _elapsedTimer: Timer {
        interval: 1000
        running:  root.recording
        repeat:   true
        onTriggered: root.elapsed++
    }

    // ── Audio bars — 6 bars, always active during recording ───────────────────
    property var audioBars: [0, 0, 0, 0, 0, 0]

    // ── Config ────────────────────────────────────────────────────────────────
    property var _configView: FileView {
        id: configView
        watchChanges: false
        onLoaded: root._parseConfig(configView.text())
    }

    property var _initConfig: Process {
        command: []
        running: false
        onExited: function() { configView.reload() }
    }

    Component.onCompleted: {
        var path = Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/screenrec.json"
        configView.path = path
        _initConfig.command = [
            "bash", "-c",
            "[ -f '" + path + "' ] || " +
            "(mkdir -p \"$(dirname '" + path + "')\" && " +
            "printf '{\"captureTarget\":\"screen\",\"audioMic\":false,\"audioSystem\":false}\\n'" +
            " > '" + path + "')"
        ]
        _initConfig.running = true
    }

    function _parseConfig(raw) {
        if (!raw || raw.trim() === "") return
        try {
            var o = JSON.parse(raw)
            if (o.captureTarget) root.captureTarget = o.captureTarget
            if (typeof o.audioMic    === "boolean") root.audioMic    = o.audioMic
            if (typeof o.audioSystem === "boolean") root.audioSystem = o.audioSystem
        } catch(e) {}
    }

    function saveConfig() {
        var path = Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/screenrec.json"
        var data = JSON.stringify({
            captureTarget: root.captureTarget,
            audioMic:      root.audioMic,
            audioSystem:   root.audioSystem
        })
        _saveProc.command = ["bash", "-c",
            "printf '%s' '" + data.replace(/'/g, "'\\''") + "' > '" + path + "'"]
        _saveProc.running = false
        _saveProc.running = true
    }

    property var _saveProc: Process { command: []; running: false }

    // ── Recording process ─────────────────────────────────────────────────────
    property string _pendingGeometry: ""
    property string _resolvedAudioDevice: ""

    property var _windowPickerProc: Process {
        command: []
        running: false
        stdout: StdioCollector {
            id: windowPickerOut
            onStreamFinished: {
                var g = windowPickerOut.text.trim()
                if (g !== "") root._pendingGeometry = g
            }
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && root._pendingGeometry !== "")
                root._resolveAudio()
            else
                root._pendingGeometry = ""
        }
    }

    property var _regionPickerProc: Process {
        command: []
        running: false
        stdout: StdioCollector {
            id: regionPickerOut
            onStreamFinished: {
                var g = regionPickerOut.text.trim()
                if (g !== "") root._pendingGeometry = g
            }
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && root._pendingGeometry !== "")
                root._resolveAudio()
            else
                root._pendingGeometry = ""
        }
    }

    // Step 1: resolve/set up audio device, then launch.
    // Reads the resolved device name from stdout (last non-empty line).
    property var _audioDeviceProc: Process {
        command: []
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var s = line.trim()
                if (s !== "") root._resolvedAudioDevice = s
            }
        }
        onExited: function(exitCode, exitStatus) {
            root._launch()
        }
    }

    // ── Audio resolution ──────────────────────────────────────────────────────
    //
    // none:        call _launch() immediately — no audio device, no null sink.
    // mic only:    get default PulseAudio source; pass straight to wf-recorder.
    // system only: create BrainShellMixer null sink, route sink.monitor into it.
    // both:        create BrainShellMixer null sink, route sink.monitor AND
    //              default source (mic) into it via two loopback modules.
    //
    function _resolveAudio() {
        root._resolvedAudioDevice = ""
        root._usingNullSink       = false

        if (!root.audioMic && !root.audioSystem) {
            // No audio — skip device resolution entirely
            root._launch()
            return
        }

        if (root.audioMic && !root.audioSystem) {
            // Mic only — use the default source directly; no null sink needed
            _audioDeviceProc.command = ["bash", "-c",
                "printf '%s\\n' \"$(pactl get-default-source)\""]
            _audioDeviceProc.running = false
            _audioDeviceProc.running = true
            return
        }

        // System audio (alone or combined with mic) — needs BrainShellMixer
        root._usingNullSink = true

        var script =
            // Clean up any stale modules from a previous crashed session
            "pactl unload-module module-loopback 2>/dev/null; " +
            "pactl unload-module module-null-sink 2>/dev/null; " +
            "sleep 0.3; " +
            // Create the virtual mixer sink
            "pactl load-module module-null-sink sink_name=BrainShellMixer >/dev/null; " +
            "sleep 0.3; " +
            // Route system audio (default sink monitor) into BrainShellMixer
            "pactl load-module module-loopback " +
            "sink=BrainShellMixer source=$(pactl get-default-sink).monitor >/dev/null"

        if (root.audioMic && root.audioSystem) {
            // Also route mic into BrainShellMixer
            script += "; pactl load-module module-loopback " +
                      "sink=BrainShellMixer source=$(pactl get-default-source) >/dev/null"
        }

        // Emit the recording device name as the final stdout line
        script += "; printf 'BrainShellMixer.monitor\\n'"

        _audioDeviceProc.command = ["bash", "-c", script]
        _audioDeviceProc.running = false
        _audioDeviceProc.running = true
    }

    // ── Null-sink teardown — run after every recording ends ───────────────────
    property var _cleanupAudioProc: Process { command: []; running: false }

    function _teardownNullSink() {
        if (!root._usingNullSink) return
        root._usingNullSink = false
        _cleanupAudioProc.command = ["bash", "-c",
            "pactl unload-module module-loopback 2>/dev/null; " +
            "pactl unload-module module-null-sink 2>/dev/null"]
        _cleanupAudioProc.running = false
        _cleanupAudioProc.running = true
    }

    // ── Notification process ──────────────────────────────────────────────────
    // Uses notify-send --wait + --action (libnotify ≥ 0.8 required).
    // Saved recording: shows "View Folder" (xdg-open dir) and "Open in MPV".
    property var _notifyProc: Process { command: []; running: false }

    // ── wf-recorder process ───────────────────────────────────────────────────
    property var _recProc: Process {
        command: []
        running: false
        onExited: function(exitCode, exitStatus) {
            var savedFile = root._currentFile   // capture before it is cleared

            root.recording        = false
            root.elapsed          = 0
            root._pendingGeometry = ""
            root._currentFile     = ""
            root._cavaRecProc.running = false
            root.audioBars        = [0, 0, 0, 0, 0, 0]
            ShellState.screenRecord = false

            // Always tear down the null sink (no-op when mic-only or no-audio)
            root._teardownNullSink()

            if (!root._discarding && savedFile !== "") {
                // Normal stop — notify with interactive action buttons.
                // FILE/"$FILE" expands $HOME correctly inside bash.
                _notifyProc.command = ["bash", "-c",
                    "FILE=\"" + savedFile + "\"; " +
                    "DIR=\"$(dirname \"$FILE\")\"; " +
                    "ACTION=$(notify-send" +
                    " --app-name 'ScreenRec'" +
                    " --icon 'video-x-generic'" +
                    " --action 'view=View Folder'" +
                    " --action 'open=Open in MPV'" +
                    " --wait" +
                    " 'Recording Saved' \"$FILE\"); " +
                    "case \"$ACTION\" in" +
                    "  view) xdg-open \"$DIR\" ;;" +
                    "  open) mpv \"$FILE\" ;;" +
                    "esac"]
                _notifyProc.running = false
                _notifyProc.running = true
            }
            // Discard path: _discardTimer handles file deletion + notification
        }
    }

    function _buildCmd() {
    var ts  = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss")
    root._currentFile = "$HOME/Videos/screen_recordings/" + ts + ".mp4"
    
    var cmd = "mkdir -p $HOME/Videos/screen_recordings && " +
              "wf-recorder -c libx264" +
              " -x yuv420p" +
              " -r 30" +                       // Limit FPS to 30
              " -p preset=fast" +              // Faster encoding speed
              " -p crf=26" +                   // Lower quality/smaller size
              " -p profile=main" +             // Maximum web/Discord compatibility
              " -p color_range=tv" +           // Fixes washed out blacks/whites
              " -p colorspace=bt709" +         // Tags the correct HD color matrix
              " -p color_primaries=bt709" +
              " -p color_trc=bt709" +
              " -f " + root._currentFile
              
    if (root._pendingGeometry !== "")
        cmd += " -g '" + root._pendingGeometry + "'"
        
    // Use --audio=DEVICE (matches wf-recorder working script convention) [cite: 48]
    if ((root.audioMic || root.audioSystem) && root._resolvedAudioDevice !== "")
        cmd += " --audio=" + root._resolvedAudioDevice
        
    return cmd
}

    function _launch() {
        _recProc.command = ["bash", "-c", root._buildCmd()]
        _recProc.running = false
        _recProc.running = true
        root.recording   = true
        root.elapsed     = 0
        root.openStrip   = ""
        if (root._resolvedAudioDevice !== "")
            _startCavaWithSource(root._resolvedAudioDevice)
    }

    function startRecording() {
        root._pendingGeometry = ""
        root._discarding      = false
        saveConfig()
        if (root.captureTarget === "screen") {
            root._resolveAudio()
        } else if (root.captureTarget === "window") {
            _windowPickerProc.command = [
                "bash", "-c",
                "hyprctl clients -j | python3 -c \"" +
                "import sys,json; ws=json.load(sys.stdin); " +
                "[print(str(w['at'][0])+','+str(w['at'][1])+' '+str(w['size'][0])+'x'+str(w['size'][1])) " +
                "for w in ws if w['mapped']]\" | slurp"
            ]
            _windowPickerProc.running = false
            _windowPickerProc.running = true
        } else {
            _regionPickerProc.command = [
                "bash", "-c",
                "hyprctl monitors -j | python3 -c \"" +
                "import sys,json; ms=json.load(sys.stdin); " +
                "[print(str(m['x'])+','+str(m['y'])+' '+str(m['width'])+'x'+str(m['height'])) for m in ms]\" | slurp"
            ]
            _regionPickerProc.running = false
            _regionPickerProc.running = true
        }
    }

    function stopRecording() {
        _sigProc.command = ["bash", "-c", "pkill -INT wf-recorder"]
        _sigProc.running = false
        _sigProc.running = true
    }

    function discardRecording() {
        root._discarding = true
        var fileToDelete = root._currentFile
        // Kill wf-recorder; _recProc.onExited will see _discarding=true and skip
        // the saved notification. The timer below handles delete + notify.
        _sigProc.command = ["bash", "-c", "pkill -INT wf-recorder"]
        _sigProc.running = false
        _sigProc.running = true
        _discardTimer.fileToDelete = fileToDelete
        _discardTimer.restart()
    }

    property var _discardTimer: Timer {
        property string fileToDelete: ""
        interval: 800
        onTriggered: {
            if (fileToDelete !== "") {
                var f = fileToDelete
                _discardDeleteProc.command = ["bash", "-c",
                    "rm -f \"" + f + "\" && " +
                    "notify-send" +
                    " --app-name 'ScreenRec'" +
                    " --icon 'video-x-generic'" +
                    " 'Recording Discarded'" +
                    " 'The recording was deleted.'"]
                _discardDeleteProc.running = false
                _discardDeleteProc.running = true
                fileToDelete        = ""
                root._discarding    = false
            }
        }
    }

    property var _discardDeleteProc: Process { command: []; running: false }

    function cancelSetup() {
        root.openStrip = ""
        ShellState.screenRecord = false
    }

    property var _sigProc: Process { command: []; running: false }

    // ── Cava — runs during recording, source mirrors wf-recorder's audio ──────
    property var _cavaRecProc: Process {
        command: []
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                if (!root.recording) return
                var t = line.trim()
                if (t === "") return
                if (t.endsWith(";")) t = t.slice(0, -1)
                var parts = t.split(";")
                if (parts.length !== 12) return
                var bars = []
                for (var i = 0; i < 12; i++) bars.push(parseInt(parts[i]) || 0)
                root.audioBars = bars
            }
        }
    }

    function _startCavaWithSource(src) {
        var config =
            "[general]\nbars = 12\nframerate = 20\nnoise_reduction = 77\n\n" +
            "[output]\nmethod = raw\nraw_target = /dev/stdout\n" +
            "data_format = ascii\nascii_max_range = 100\n" +
            "bar_delimiter = 59\nframe_delimiter = 10\n\n" +
            "[input]\nmethod = pulse\nsource = " + src + "\n"

        _cavaRecProc.command = [
            "bash", "-c",
            "mkdir -p /tmp/brain_shell && printf '%s\\n' '" +
            config.replace(/'/g, "'\\''") +
            "' > /tmp/brain_shell/cava_rec.ini && " +
            "exec cava -p /tmp/brain_shell/cava_rec.ini 2>/dev/null"
        ]
        _cavaRecProc.running = false
        _cavaRecProc.running = true
    }
}
