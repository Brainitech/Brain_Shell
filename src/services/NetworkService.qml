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
import Quickshell.Io
import Quickshell
import "../state"

QtObject {
    id: root

    property int signal: 0
    property bool ethernet: false
    property string connectivity: ""

    property string ethernetName: ""

    property var masterPoll: Process {
        command: [
            "bash", "-c",
            "wifi=$(awk 'NR>2 {print int($3*100/70); exit}' /proc/net/wireless 2>/dev/null); " +
            "eth=$(nmcli -t -f TYPE,STATE,CONNECTION dev 2>/dev/null | grep -i 'ethernet:connected' | head -1 | cut -d: -f3-); " +
            "conn=$(nmcli -t -f CONNECTIVITY general 2>/dev/null | head -1); " +
            "bt_pow=$(bluetoothctl show 2>/dev/null | grep -i 'Powered: yes' >/dev/null && echo 'yes' || echo 'no'); " +
            "bt_conn=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-); " +
            "echo \"${wifi:--1}|${eth}|${conn}|${bt_pow}|${bt_conn}\""
        ]
        running: false
        stdout: SplitParser {
            onRead: function(l) {
                var p = l.trim().split("|")
                if (p.length >= 5) {
                    var s = parseInt(p[0])
                    root.signal = isNaN(s) || s < 0 ? 0 : s
                    root.ethernetName = p[1]
                    root.ethernet = (p[1] !== "")
                    if (p[2] !== "") root.connectivity = p[2].toLowerCase()
                    ShellState.btPowered = (p[3] === "yes")
                    ShellState.btConnected = (p[4] !== "")
                }
            }
        }
    }

    property var pollTimer: Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.masterPoll.running = true
    }
}
