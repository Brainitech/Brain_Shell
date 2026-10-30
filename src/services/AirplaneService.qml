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
import "./"

QtObject {
    id: root

    property bool airplaneOn: false
    property bool wasWifiOn: true
    property bool wasBtOn: false

    property var _wifiConn: Connections {
        target: WifiService
        function onWifiOnChanged() {
            if (!root.airplaneOn) {
                root.wasWifiOn = WifiService.wifiOn
            }
        }
    }

    property var _btConn: Connections {
        target: BluetoothService
        function onBtOnChanged() {
            if (!root.airplaneOn) {
                root.wasBtOn = BluetoothService.btOn
            }
        }
    }

    property var airplaneCheck: Process {
        command: ["bash", "-c",
            "notBlocked=$(rfkill list all 2>/dev/null | grep -c 'Soft blocked: no');" +
            " total=$(rfkill list all 2>/dev/null | grep -c 'Soft blocked:');" +
            " [ \"$total\" -gt 0 ] && [ \"$notBlocked\" -eq 0 ] && echo yes || echo no"]
        running: false
        stdout: SplitParser {
            onRead: function(l) {
                var on = l.trim() === "yes"
                if (root.airplaneOn !== on) {
                    if (!root.airplaneOn && on) {
                        root.wasWifiOn = WifiService.wifiOn
                        root.wasBtOn = BluetoothService.btOn
                    }
                    root.airplaneOn = on
                    ShellState.airplane = on
                }
            }
        }
    }

    property var airplaneOn_proc: Process {
        command: ["bash", "-c", "rfkill block all"]
        running: false
        onRunningChanged: if (!running) {
            WifiService.poll()
            BluetoothService.poll()
        }
    }

    property var restoreProc: Process {
        command: []
        running: false
        onRunningChanged: if (!running) {
            WifiService.poll()
            BluetoothService.poll()
            root.check()
        }
    }

    function check() {
        airplaneCheck.running = false
        airplaneCheck.running = true
    }

    function toggle() {
        if (root.airplaneOn) {
            // Turning OFF airplane mode -> restore previous states
            root.airplaneOn = false
            ShellState.airplane = false

            var cmds = []
            if (root.wasWifiOn) {
                cmds.push("rfkill unblock wifi 2>/dev/null; nmcli radio wifi on")
            } else {
                cmds.push("nmcli radio wifi off; rfkill block wifi 2>/dev/null || true")
            }

            if (root.wasBtOn) {
                cmds.push("rfkill unblock bluetooth 2>/dev/null; for i in {1..15}; do bluetoothctl power on 2>/dev/null && break; sleep 0.1; done")
            } else {
                cmds.push("bluetoothctl power off 2>/dev/null; rfkill block bluetooth 2>/dev/null || true")
            }

            restoreProc.command = ["bash", "-c", "(" + cmds.join(") & (") + ") & wait"]
            restoreProc.running = false
            restoreProc.running = true
        } else {
            // Turning ON airplane mode -> record current states
            root.wasWifiOn = WifiService.wifiOn
            root.wasBtOn = BluetoothService.btOn

            root.airplaneOn = true
            ShellState.airplane = true

            airplaneOn_proc.command = ["bash", "-c", "rfkill block all"]
            airplaneOn_proc.running = false
            airplaneOn_proc.running = true
        }
    }

    property var pollTimer: Timer {
        interval: 15000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    Component.onCompleted: {
        root.wasWifiOn = WifiService.wifiOn
        root.wasBtOn = BluetoothService.btOn
        root.check()
    }
}
