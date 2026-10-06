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
    property bool available: false

    property var _checkProc: Process {
        command: ["sh", "-c", "nbfc status >/dev/null 2>&1"]
        running: true
        onExited: (code) => { root.available = (code === 0) }
    }
    property bool   busy: false
    

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