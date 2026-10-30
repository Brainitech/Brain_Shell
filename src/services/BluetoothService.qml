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

    property bool   btOn:     ShellState.btPowered
    property string btDevice: ""

    property var btPowerRead: Process {
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep '^\\s*Powered:' | awk '{print $2}'"]
        running: false
        stdout: SplitParser {
            onRead: function(l) {
                root.btOn = l.trim() === "yes"
                ShellState.btPowered = root.btOn
            }
        }
    }

    property var btDeviceRead: Process {
        command: ["bash", "-c", "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-"]
        running: false
        stdout: SplitParser {
            onRead: function(l) {
                root.btDevice = l.trim()
                ShellState.btConnected = (root.btDevice !== "")
            }
        }
    }

    property var btToggleProc: Process {
        command: []
        running: false
        onRunningChanged: if (!running) {
            root.poll()
        }
    }

    property var _shellConn: Connections {
        target: ShellState
        function onBtPoweredChanged() {
            root.btOn = ShellState.btPowered
        }
    }

    function poll() {
        btPowerRead.running = false
        btPowerRead.running = true
        btDeviceRead.running = false
        btDeviceRead.running = true
    }

    function setPower(on) {
        root.btOn = on
        ShellState.btPowered = on
        if (!on) ShellState.btConnected = false

        btToggleProc.command = ["bash", "-c", on
            ? "rfkill unblock bluetooth 2>/dev/null; for i in {1..15}; do bluetoothctl power on 2>/dev/null && break; sleep 0.1; done"
            : "bluetoothctl power off 2>/dev/null; rfkill block bluetooth 2>/dev/null || true"
        ]
        btToggleProc.running = false
        btToggleProc.running = true
    }

    function toggle() {
        setPower(!root.btOn)
    }

    property var pollTimer: Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    Component.onCompleted: {
        root.poll()
    }
}
