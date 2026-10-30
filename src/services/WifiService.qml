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

    property bool   wifiOn:   false
    property string wifiSSID: ""

    property var wifiRadioRead: Process {
        command: ["bash", "-c", "nmcli radio wifi"]
        running: false
        stdout: SplitParser {
            onRead: function(l) {
                root.wifiOn = l.trim() === "enabled"
                ShellState.wifiOn = root.wifiOn && !ShellState.hotspot
            }
        }
    }

    property var wifiSSIDRead: Process {
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | head -1 | cut -d: -f2"]
        running: false
        stdout: SplitParser {
            onRead: function(l) {
                root.wifiSSID = l.trim()
            }
        }
    }

    property var wifiToggleProc: Process {
        command: []
        running: false
        onRunningChanged: if (!running) root.poll()
    }

    function poll() {
        wifiRadioRead.running = false
        wifiRadioRead.running = true
        wifiSSIDRead.running = false
        wifiSSIDRead.running = true
    }

    function toggle() {
        if (ShellState.hotspot) return
        var next = !root.wifiOn
        root.wifiOn = next
        ShellState.wifiOn = next
        wifiToggleProc.command = ["bash", "-c", "nmcli radio wifi " + (next ? "on" : "off")]
        wifiToggleProc.running = false
        wifiToggleProc.running = true
    }

    function setWifiState(on) {
        root.wifiOn = on
        ShellState.wifiOn = on
    }

    property var _hotspotConn: Connections {
        target: ShellState
        function onHotspotChanged() {
            ShellState.wifiOn = root.wifiOn && !ShellState.hotspot
        }
    }

    property var pollTimer: Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    Component.onCompleted: {
        root.poll()
    }
}
