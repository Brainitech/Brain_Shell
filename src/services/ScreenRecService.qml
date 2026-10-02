/*
 * Brain Shell
 * Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
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

    property real popupTargetX: 0
    property real popupTargetWidth: 0
    
    
    
    

    // ── Backends ──────────────────────────────────────────────────────────────
    // wf-recorder is the default; the other two are useful when it struggles
    // (gpu-screen-recorder for GPU encoding, wl-screenrec as a lighter
    // alternative). The chosen binary is also what stop/discard signals.
    readonly property var backends: [
        { id: "wf",   label: "wf-recorder",  binary: "wf-recorder" },
        { id: "gsr",  label: "GPU Recorder", binary: "gpu-screen-recorder" },
        { id: "wlsr", label: "wl-screenrec", binary: "wl-screenrec" },
    ]

    readonly property string backendBinary: {
        var b = root.backends.find(function(x) { return x.id === PrefsService.screenrecBackend })
        return b ? b.binary : "wf-recorder"
    }

    // ── Display helpers ───────────────────────────────────────────────────────
    readonly property var _captureIcons:  ({ screen: "󰍹", window: "󱂬", region: "󰩭" })
    readonly property var _captureLabels: ({ screen: "Screen", window: "Window", region: "Region" })
    readonly property string captureIcon:  _captureIcons[PrefsService.screenrecCaptureTarget]  ?? "󰍹"
    readonly property string captureLabel: _captureLabels[PrefsService.screenrecCaptureTarget] ?? "Screen"

    readonly property string audioLabel: {
        if (PrefsService.screenrecAudioMic && PrefsService.screenrecAudioSystem) return "Mic + Sys"
        if (PrefsService.screenrecAudioMic)                return "Mic"
        if (PrefsService.screenrecAudioSystem)             return "Sys"
        return "Non"
    }

    // ── Escape to cancel ──────────────────────────────────────────────────────
    // Bound non-consuming in the generated keybinds, so Escape still reaches
    // whatever app is focused; we only react while setup is actually open.
    // This replaces grabbing exclusive keyboard focus for the setup strip,
    // which used to block all typing.
    property var _cancelShortcut: GlobalShortcut {
        appid: "quickshell"
        name:  "screenrecCancel"
        onPressed: {
            if (root.recording || !ShellState.screenRecord) return
            if (root.optionsExpanded) root.optionsExpanded = false
            else                      root.cancelSetup()
        }
    }

    // ── Expansion state ─────────────────────────
    property bool optionsExpanded: false
    
    property var _expandTimer: Timer {
        interval: 250
        onTriggered: root.optionsExpanded = true
    }
    
    property var _closeTimer: Timer {
        interval: 100
        onTriggered: root.optionsExpanded = false
    }
    
    function requestExpand() {
        _closeTimer.stop()
        if (!optionsExpanded) _expandTimer.restart()
    }
    
    function keepExpanded() {
        _closeTimer.stop()
        _expandTimer.stop()
        root.optionsExpanded = true
    }
    
    function scheduleClose() {
        _expandTimer.stop()
        _closeTimer.restart()
    }

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

        if (!PrefsService.screenrecAudioMic && !PrefsService.screenrecAudioSystem) {
            // No audio — skip device resolution entirely
            root._launch()
            return
        }

        if (PrefsService.screenrecAudioMic && !PrefsService.screenrecAudioSystem) {
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

        if (PrefsService.screenrecAudioMic && PrefsService.screenrecAudioSystem) {
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
                // The backend exiting is not proof it worked — a missing binary
                // or an unsupported codec dies immediately and writes nothing.
                // Check the file actually landed before claiming "Saved".
                // FILE/"$FILE" expands $HOME correctly inside bash.
                _notifyProc.command = ["bash", "-c",
                    "FILE=\"" + savedFile + "\"; " +
                    "if [ -s \"$FILE\" ]; then " +
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
                    "esac; " +
                    "else " +
                    "notify-send --app-name 'ScreenRec' --icon 'dialog-error' -u critical" +
                    " 'Recording Failed'" +
                    " \"" + root.backendBinary + " did not produce a file. Check that it is installed and supports your GPU/codec.\"; " +
                    "fi"]
                _notifyProc.running = false
                _notifyProc.running = true
            }
            // Discard path: _discardTimer handles file deletion + notification
        }
    }

    function _buildCmd() {
        var saveDir = PrefsService.screenrecSaveDir.replace(/^~/, Quickshell.env("HOME")).replace(/\/+$/, "")
        var ts  = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss")
        root._currentFile = saveDir + "/" + ts + ".mp4"
        
        var fps = PrefsService.screenrecFramerate > 0 ? PrefsService.screenrecFramerate : 30
        var file = root._currentFile.replace(/'/g, "'\\''")
        var mkdir = "mkdir -p '" + saveDir.replace(/'/g, "'\\''") + "' && "
        var hasAudio = (PrefsService.screenrecAudioMic || PrefsService.screenrecAudioSystem)
                       && root._resolvedAudioDevice !== ""

        if (PrefsService.screenrecBackend === "gsr") {
            var gsr = "gpu-screen-recorder -f " + fps + " -k h264 -cursor yes -o '" + file + "'"
            if (root._pendingGeometry !== "") {
                // "X,Y WxH" -> WxH+X+Y
                var parts = root._pendingGeometry.split(" ")
                gsr += " -w region -region '" + parts[1] + "+" + parts[0].replace(",", "+") + "'"
            } else {
                gsr += " -w screen"
            }
            if (hasAudio) gsr += " -a " + root._resolvedAudioDevice
            return mkdir + gsr
        }

        if (PrefsService.screenrecBackend === "wlsr") {
            var wlsr = "wl-screenrec -f '" + file + "' --max-fps " + fps
            if (root._pendingGeometry !== "")
                wlsr += " -g '" + root._pendingGeometry + "'"
            if (hasAudio)
                wlsr += " --audio --audio-device " + root._resolvedAudioDevice
            return mkdir + wlsr
        }

        var cmd = mkdir +
                  "wf-recorder -c libx264" +
                  " -x yuv420p" +
                  " -r " + fps +                   // Configurable FPS
                  " -p preset=fast" +              // Faster encoding speed
                  " -p crf=20" +                   // Balanced quality/medium size
                  " -p profile=main" +             // Maximum web/Discord compatibility
                  " -p color_range=tv" +           // Fixes washed out blacks/whites
                  " -p colorspace=bt709" +         // Tags the correct HD color matrix
                  " -p color_primaries=bt709" +
                  " -p color_trc=bt709" +
                  " -f '" + file + "'"

        if (root._pendingGeometry !== "")
            cmd += " -g '" + root._pendingGeometry + "'"

        // Use --audio=DEVICE (matches wf-recorder working script convention)
        if (hasAudio)
            cmd += " --audio=" + root._resolvedAudioDevice

        return cmd
    }

    function _launch() {
        _recProc.command = ["bash", "-c", root._buildCmd()]
        _recProc.running = false
        _recProc.running = true
        root.recording   = true
        root.elapsed     = 0
        root.optionsExpanded = false
        if (root._resolvedAudioDevice !== "")
            _startCavaWithSource(root._resolvedAudioDevice)
    }

    function startRecording() {
        root.optionsExpanded = false
        root._pendingGeometry = ""
        root._discarding      = false
        if (PrefsService.screenrecCaptureTarget === "screen") {
            root._resolveAudio()
        } else if (PrefsService.screenrecCaptureTarget === "window") {
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
        _sigProc.command = ["bash", "-c", "pkill -INT " + root.backendBinary]
        _sigProc.running = false
        _sigProc.running = true
    }

    function discardRecording() {
        root._discarding = true
        var fileToDelete = root._currentFile
        // Kill wf-recorder; _recProc.onExited will see _discarding=true and skip
        // the saved notification. The timer below handles delete + notify.
        _sigProc.command = ["bash", "-c", "pkill -INT " + root.backendBinary]
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
        root.optionsExpanded = false
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
