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
import "../../"

// Queries envycontrol on load and after each switch.
// Switching requires reboot — uses Popups.showConfirm().
//
// currentMode is ONLY ever set from an envycontrol --query result,
// never optimistically. If pkexec is cancelled, the re-query after
// the process exits will return the unchanged real mode.
//
// Extra hardening: re-query is only triggered when exitCode === 0,
// so a cancelled pkexec leaves currentMode visually unchanged until
// the next scheduled query.
//
// Exposes:
//   string currentMode  — "integrated" | "hybrid" | "nvidia"
//   bool   busy         — true while a switch command is running
//   function switchMode(mode)

QtObject {
    id: root

    property string currentMode: "integrated"
    property bool available: false

    property var _checkProc: Process {
        command: ["sh", "-c", "command -v envycontrol"]
        running: true
        onExited: (code) => { 
            root.available = (code === 0) 
            if (root.available) {
                _queryProc.running = true
            }
        }
    }

    // Pending mode — held until we confirm the switch succeeded

    // ── Query current mode ────────────────────────────────────────────────────
    property var _queryProc: Process {
        command: ["envycontrol", "--query"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var mode = text.trim().toLowerCase()
                if (mode === "integrated" || mode === "hybrid" || mode === "nvidia") {
                    root.currentMode = mode
                } else {
                    root.currentMode = "integrated"
                }
            }
        }
    }

    function switchMode(mode) {
        if (!root.available || mode === root.currentMode || root.busy) return
        Popups.closeAll()
        Popups.showConfirm(
            "Switch GPU Mode",
            "Switch to " + mode + " mode?\nA reboot is required for the change to take effect.",
            "Switch + Reboot",
            "gpu-switch-envy",
            mode
        )
    }
}
