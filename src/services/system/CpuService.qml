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

// Reads /proc/stat every second via cat and computes CPU usage %.
// Exposes:
//   real usagePercent   — 0.0 to 100.0

QtObject {
    id: root

    property bool active:       true
    property real usagePercent: 0.0

    property real _prevIdle:  0
    property real _prevTotal: 0
    property bool _firstRead: true

    property var _proc: Process {
        command: ["cat", "/proc/stat"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    property var _timer: Timer {
        interval: 1000
        running:  root.active
        repeat:   true
        onTriggered: {
            _proc.running = false
            _proc.running = true
        }
    }

    function _parse(text) {
        var line  = text.split("\n")[0]
        var parts = line.trim().split(/\s+/)
        if (parts.length < 8 || parts[0] !== "cpu") return

        var user    = parseFloat(parts[1])
        var nice    = parseFloat(parts[2])
        var system  = parseFloat(parts[3])
        var idle    = parseFloat(parts[4])
        var iowait  = parseFloat(parts[5])
        var irq     = parseFloat(parts[6])
        var softirq = parseFloat(parts[7])
        var steal   = parts.length > 8 ? parseFloat(parts[8]) : 0

        var totalIdle = idle + iowait
        var total     = user + nice + system + totalIdle + irq + softirq + steal

        if (!root._firstRead) {
            var dTotal = total - root._prevTotal
            var dIdle  = totalIdle - root._prevIdle
            if (dTotal > 0)
                root.usagePercent = Math.round((1 - dIdle / dTotal) * 100)
        }

        root._firstRead = false
        root._prevTotal = total
        root._prevIdle  = totalIdle
    }

    Component.onCompleted: {
        _proc.running = true
    }
}
