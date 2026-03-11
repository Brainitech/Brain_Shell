import QtQuick
import Quickshell.Io

// Controls fans via nbfc-linux.
// Default mode assumes "auto" — set by hyprland exec-once at startup.
//
// Modes:
//   "quiet" → nbfc set -s 0
//   "auto"  → nbfc set -a
//   "max"   → nbfc set -s 100
//
// Commands wrapped in `timeout 5` to prevent hanging on unavailable sensors.
//
// Exposes:
//   string mode         — "quiet" | "auto" | "max"
//   bool   busy         — true while a command is in flight
//   function setMode(m)

QtObject {
    id: root

    property string mode: "auto"
    property bool   busy: false
    
    // ── Status query — runs once on load ──────────────────────────────────────
property var _statusProc: Process {
    command: ["sh", "-c", "nbfc status 2>/dev/null"]
    running: false
    stdout: StdioCollector {
        onStreamFinished: root._parseStatus(text)
    }
}

function _parseStatus(text) {
    var autoEnabled = false
    var requestedSpeed = -1

    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i]

        var autoMatch = line.match(/Auto Control Enabled\s*:\s*(true|false)/i)
        if (autoMatch) {
            autoEnabled = autoMatch[1].toLowerCase() === "true"
            continue
        }

        var speedMatch = line.match(/Requested Fan Speed\s*:\s*([0-9.]+)/i)
        if (speedMatch) {
            requestedSpeed = parseFloat(speedMatch[1])
        }
    }

    if (autoEnabled) {
        root.mode = "auto"
    } else {
        root.mode = (requestedSpeed === 100.00) ? "max" : "quiet"
    }
}

Component.onCompleted: {
    _statusProc.running = true
}

    property var _proc: Process {
        command: []
        running: false
        onRunningChanged: if (!running) root.busy = false
    }

    function setMode(m) {
        if (root.busy) return
        root.mode = m
        root.busy = true

        if      (m === "quiet") _proc.command = ["sh", "-c", "timeout 5 nbfc set -s 30"]
        else if (m === "max")   _proc.command = ["sh", "-c", "timeout 5 nbfc set -s 100"]
        else                    _proc.command = ["sh", "-c", "timeout 5 nbfc set -a"]

        _proc.running = false
        _proc.running = true
    }
}