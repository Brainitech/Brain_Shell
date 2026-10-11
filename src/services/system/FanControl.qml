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

import QtQuick
import Quickshell.Io

// Controls fans via nbfc-linux.
// Queries nbfc status on startup and dashboard reveal to detect backend mode.
//
// Modes:
//   "quiet" → nbfc set -s 30
//   "auto"  → nbfc set -a
//   "max"   → nbfc set -s 100
//
// Commands wrapped in `timeout 5` to prevent hanging on unavailable sensors.
//
// Exposes:
//   string mode         — "quiet" | "auto" | "max"
//   bool   available    — true if nbfc is installed and responding
//   bool   busy         — true while a command is in flight
//   bool   active       — drives refresh on UI reveal
//   function setMode(m)
//   function refresh()

QtObject {
    id: root

    property string mode: "auto"
    property bool available: false
    property bool busy: false
    property bool active: false

    onActiveChanged: {
        if (active && available && !busy) {
            refresh()
        }
    }

    // ── Status query process ──────────────────────────────────────────────────
    property var _queryProc: Process {
        command: ["sh", "-c", "timeout 5 nbfc status 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root._parseStatus(text)
        }
        onExited: (code) => {
            root.available = (code === 0)
        }
    }

    // ── Mode command process ──────────────────────────────────────────────────
    property var _proc: Process {
        command: []
        running: false
        onExited: (code) => {
            root.busy = false
            root.refresh()
        }
    }

    function _parseStatus(text) {
        if (!text || text.trim() === "") return

        // Auto mode if auto control is enabled
        if (/Auto Control Enabled\s*:\s*true/i.test(text)) {
            root.mode = "auto"
            return
        }

        // Manual mode: evaluate target fan speed
        var speeds = []
        var re = /Target Fan Speed\s*:\s*([0-9.]+)/gi
        var m
        while ((m = re.exec(text)) !== null) {
            speeds.push(parseFloat(m[1]))
        }

        if (speeds.length > 0) {
            var maxSpeed = Math.max.apply(null, speeds)
            if (maxSpeed >= 70.0) {
                root.mode = "max"
            } else if (maxSpeed <= 40.0) {
                root.mode = "quiet"
            } else {
                root.mode = "auto"
            }
            return
        }

        root.mode = "auto"
    }

    function refresh() {
        if (root.busy) return
        _queryProc.running = false
        _queryProc.running = true
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