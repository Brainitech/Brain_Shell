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
import "../"
import "../state"
import "./"

QtObject {
    id: root

    property bool   hotspotOn:     false
    property bool   hotspotBusy:   false
    property bool   _hsWifiWasOff: false
    property string hotspotLabel:  ""
    readonly property string _hsSSID:     PrefsService.hotspotSsid
    readonly property string _hsPassword: PrefsService.hotspotPassword
    property string _hsWifiIface:  "wlan0"

    // Detect WiFi interface name
    property var hsIfaceProc: Process {
        command: ["bash", "-c",
            "nmcli -g DEVICE,TYPE dev 2>/dev/null | awk -F: '$2==\"wifi\"{print $1; exit}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var n = text.trim()
                if (n !== "") root._hsWifiIface = n
            }
        }
    }

    // Check if ethernet is connected
    property var hsEthernetCheck: Process {
        command: ["bash", "-c",
            "nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -c 'ethernet:connected'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var hasEth = parseInt(text.trim()) > 0
                if (!hasEth) {
                    root.hotspotLabel = "Not on ethernet"
                    root.hotspotBusy  = false
                    return
                }
                // Remember whether wifi radio was off so we can restore it on stop
                root._hsWifiWasOff = !WifiService.wifiOn
                root._hsDoStart()
            }
        }
    }

    // Check hotspot status
    property var hotspotCheck: Process {
        command: ["bash", "-c",
            "nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -c 'wifi:connected'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.hsActiveCheckProc.running = false
                root.hsActiveCheckProc.running = true
            }
        }
    }

    property var hsActiveCheckProc: Process {
        command: ["bash", "-c",
            "nmcli -t -f NAME,STATE,DEVICE con show --active 2>/dev/null" +
            " | awk -F: '$1~/[Hh]otspot/{found=1} END{print found+0}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.hotspotOn     = parseInt(text.trim()) > 0
                ShellState.hotspot = root.hotspotOn
                root.hotspotLabel  = root.hotspotOn ? "Active" : ""
                if (root.hotspotOn) ShellState.wifiOn = false
            }
        }
    }

    // Start hotspot
    property var hsStartProc: Process {
        command: []
        running: false
        onRunningChanged: if (!running) {
            root.hotspotBusy = false
            root.hsActiveCheckProc.running = false
            root.hsActiveCheckProc.running = true
        }
        onExited: function(code, status) {
            if (code === 0) {
                root.hotspotOn     = true
                root.hotspotLabel  = "Active"
                ShellState.hotspot = true
                ShellState.wifiOn  = false
            } else {
                root.hotspotOn     = false
                root.hotspotLabel  = "Failed"
                ShellState.hotspot = false
                root.hsLabelResetTimer.restart()
            }
        }
    }

    // Process to turn off wifi radio when restoring state
    property var hsWifiOffProc: Process {
        command: ["bash", "-c", "nmcli radio wifi off"]
        running: false
    }

    // Stop hotspot
    property var hsStopProc: Process {
        command: ["bash", "-c",
            "nmcli device disconnect " + root._hsWifiIface + " 2>/dev/null; " +
            "nmcli con delete BrainShellHotspot 2>/dev/null; true"]
        running: false
        onRunningChanged: if (!running) {
            root.hotspotBusy   = false
            root.hotspotOn     = false
            ShellState.hotspot = false
            if (root._hsWifiWasOff) {
                WifiService.setWifiState(false)
                root.hsWifiOffProc.running = false
                root.hsWifiOffProc.running = true
                root._hsWifiWasOff = false
            } else {
                ShellState.wifiOn = WifiService.wifiOn
                WifiService.poll()
            }
        }
    }

    property var hsLabelResetTimer: Timer {
        interval: 3000
        repeat: false
        onTriggered: {
            if (root.hotspotLabel === "Failed") root.hotspotLabel = ""
        }
    }

    property var hsLivePollTimer: Timer {
        interval: 5000
        repeat: true
        running: root.hotspotOn || Popups.dashboardOpen
        onTriggered: {
            root.poll()
            if (root.hotspotOn && !root.hotspotBusy) {
                root.checkEthernetLive()
            }
        }
    }

    // Ethernet disconnect watcher
    property var hsEthernetLiveCheck: Process {
        command: ["bash", "-c",
            "nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -c 'ethernet:connected'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.hotspotOn || root.hotspotBusy) return
                var hasEth = parseInt(text.trim()) > 0
                if (!hasEth) {
                    root.hotspotLabel = "Ethernet lost"
                    root.hotspotBusy  = true
                    root.hsStopProc.command = ["bash", "-c",
                        "nmcli device disconnect " + root._hsWifiIface + " 2>/dev/null; " +
                        "nmcli con delete BrainShellHotspot 2>/dev/null; true"]
                    root.hsStopProc.running = false
                    root.hsStopProc.running = true
                    root.hsLabelResetTimer.restart()
                }
            }
        }
    }

    function _hsDoStart() {
        var ssid  = root._hsSSID
        var pass  = root._hsPassword
        var iface = root._hsWifiIface
        hsStartProc.command = ["bash", "-c",
            "nmcli radio wifi on 2>/dev/null; " +
            "sleep 1; " +
            "nmcli device disconnect \"" + iface + "\" 2>/dev/null; " +
            "nmcli con delete BrainShellHotspot 2>/dev/null; " +
            "nmcli device wifi hotspot " +
                "ifname \"" + iface + "\" " +
                "ssid \"" + ssid + "\" " +
                "password \"" + pass + "\" " +
                "con-name BrainShellHotspot 2>&1"]
        hsStartProc.running = false
        hsStartProc.running = true
    }

    function toggle() {
        if (root.hotspotBusy) return
        if (root.hotspotOn) {
            root.hotspotBusy  = true
            root.hotspotLabel = ""
            hsStopProc.command = ["bash", "-c",
                "nmcli device disconnect \"" + root._hsWifiIface + "\" 2>/dev/null; " +
                "nmcli con delete BrainShellHotspot 2>/dev/null; true"]
            hsStopProc.running = false
            hsStopProc.running = true
        } else {
            root.hotspotBusy  = true
            root.hotspotLabel = ""
            hsEthernetCheck.running = false
            hsEthernetCheck.running = true
        }
    }

    function poll() {
        hsActiveCheckProc.running = false
        hsActiveCheckProc.running = true
    }

    function checkEthernetLive() {
        hsEthernetLiveCheck.running = false
        hsEthernetLiveCheck.running = true
    }

    function init() {
        hotspotCheck.running      = true
        hsIfaceProc.running       = true
        hsActiveCheckProc.running = true
    }

    Component.onCompleted: init()
}
