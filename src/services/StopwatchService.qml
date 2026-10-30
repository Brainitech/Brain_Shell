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
import "../state"

QtObject {
    id: root

    property int  ms:      0
    property bool running: false
    property bool started: false

    function _zp(n) { return n < 10 ? "0" + n : "" + n }

    readonly property string display: {
        var t = Math.floor(ms / 1000)
        return _zp(Math.floor(t / 60)) + ":" + _zp(t % 60)
    }

    function toggleRunning() {
        running = !running
        started = true
        _syncClockState()
    }

    function reset() {
        ms      = 0
        running = false
        started = false
        _syncClockState()
    }

    property var tickTimer: Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            root.ms += 1000
            root._syncClockState()
        }
    }

    function _syncClockState() {
        ClockState.swRunning = root.running
        ClockState.swDisplay = root.display
        ClockState.swStarted = root.started
    }

    property var _clockConn: Connections {
        target: ClockState
        function onSwRunningChanged() {
            if (root.running !== ClockState.swRunning) {
                root.running = ClockState.swRunning
                if (root.running) root.started = true
            }
        }
        function onRequestStopwatchReset() {
            root.reset()
        }
    }

    Component.onCompleted: {
        _syncClockState()
    }
}
