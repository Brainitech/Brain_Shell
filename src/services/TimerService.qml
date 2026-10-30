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
import "../state"

QtObject {
    id: root

    property int  total:   10 * 60
    property int  left:    10 * 60
    property bool running: false
    property bool started: false
    property bool fired:   false

    function _zp(n) { return n < 10 ? "0" + n : "" + n }

    readonly property string display: {
        var h = Math.floor(left / 3600)
        var m = Math.floor((left % 3600) / 60)
        var s = left % 60
        return h > 0
            ? _zp(h) + ":" + _zp(m) + ":" + _zp(s)
            : _zp(m) + ":" + _zp(s)
    }

    readonly property real progress: total > 0 ? (total - left) / total : 0.0

    function totalLabel() {
        var h = Math.floor(total / 3600)
        var m = Math.floor((total % 3600) / 60)
        var s = total % 60
        if (h > 0) return h + "h " + _zp(m) + "m"
        if (m > 0 && s > 0) return m + "m " + s + "s"
        if (m > 0) return m + "m"
        return s + "s"
    }

    property var notifyProc: Process {
        command: []
        running: false
    }

    function _notify(title, body) {
        notifyProc.command = ["notify-send", "-a", "Brain Shell", "-i", "alarm", title, body]
        notifyProc.running = false
        notifyProc.running = true
    }

    function setTimer(totalSecs) {
        total   = totalSecs
        left    = totalSecs
        running = false
        fired   = false
        started = false
        _syncClockState()
    }

    function toggleRunning() {
        if (left <= 0) return
        running = !running
        started = true
        fired   = false
        _syncClockState()
    }

    function reset() {
        left    = total
        running = false
        fired   = false
        started = false
        _syncClockState()
    }

    property var tickTimer: Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.left > 0) {
                root.left--
                if (root.left === 0) {
                    root.running = false
                    if (!root.fired) {
                        root.fired = true
                        root._notify("Timer finished", "Your " + root.totalLabel() + " timer is done.")
                    }
                }
            }
            root._syncClockState()
        }
    }

    function _syncClockState() {
        ClockState.timerRunning = root.running
        ClockState.timerLeft    = root.left
        ClockState.timerTotal   = root.total
        ClockState.timerDisplay = root.display
        ClockState.timerStarted = root.started
    }

    property var _clockConn: Connections {
        target: ClockState
        function onTimerRunningChanged() {
            if (root.running !== ClockState.timerRunning) {
                if (ClockState.timerRunning && root.left <= 0) {
                    ClockState.timerRunning = false
                    return
                }
                root.running = ClockState.timerRunning
                if (root.running) root.started = true
            }
        }
        function onRequestTimerReset() {
            root.reset()
        }
    }

    Component.onCompleted: {
        _syncClockState()
    }
}
