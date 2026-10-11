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
import Quickshell
import Quickshell.Io
import "../../"
import "../"

Item {
    id: hotspotRoot
    visible: false

    property bool   hotspotOn:     false
    property bool   hotspotBusy:   false
    property bool   _hsWifiWasOff: false
    property string hotspotLabel:  ""
    property string _hsSSID:       PrefsService.hotspotSsid
    property string _hsPassword:   PrefsService.hotspotPassword
    property string _hsWifiIface:  "wlan0"

    // Property bound from host QuickSettings
    property bool   wifiOn:        false

    signal wifiStateChanged(bool on)
    signal requestWifiPoll()

    // Detect WiFi interface name
    Process {
        id: hsIfaceProc
        command: ["bash", "-c",
            "nmcli -g DEVICE,TYPE dev 2>/dev/null | awk -F: '$2==\"wifi\"{print $1; exit}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var n = text.trim()
                if (n !== "") hotspotRoot._hsWifiIface = n
            }
        }
    }

    // Check if ethernet is connected
    Process {
        id: hsEthernetCheck
        command: ["bash", "-c",
            "nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -c 'ethernet:connected'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var hasEth = parseInt(text.trim()) > 0
                if (!hasEth) {
                    hotspotRoot.hotspotLabel = "Not on ethernet"
                    hotspotRoot.hotspotBusy  = false
                    return
                }
                // Remember whether wifi radio was off so we can restore it on stop
                hotspotRoot._hsWifiWasOff = !hotspotRoot.wifiOn
                hotspotRoot._hsDoStart()
            }
        }
    }

    // Check hotspot status
    Process {
        id: hotspotCheck
        command: ["bash", "-c",
            "nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -c 'wifi:connected'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                hsActiveCheckProc.running = false
                hsActiveCheckProc.running = true
            }
        }
    }

    Process {
        id: hsActiveCheckProc
        command: ["bash", "-c",
            "nmcli -t -f NAME,STATE,DEVICE con show --active 2>/dev/null" +
            " | awk -F: '$1~/[Hh]otspot/{found=1} END{print found+0}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                hotspotRoot.hotspotOn     = parseInt(text.trim()) > 0
                ShellState.hotspot        = hotspotRoot.hotspotOn
                hotspotRoot.hotspotLabel  = hotspotRoot.hotspotOn ? "Active" : ""
                if (hotspotRoot.hotspotOn) ShellState.wifiOn = false
            }
        }
    }

    // Start hotspot
    Process {
        id: hsStartProc
        command: []
        running: false
        onRunningChanged: if (!running) {
            hotspotRoot.hotspotBusy = false
            hsActiveCheckProc.running = false
            hsActiveCheckProc.running = true
        }
        onExited: function(code, status) {
            if (code === 0) {
                hotspotRoot.hotspotOn     = true
                hotspotRoot.hotspotLabel  = "Active"
                ShellState.hotspot        = true
                ShellState.wifiOn         = false
            } else {
                hotspotRoot.hotspotOn     = false
                hotspotRoot.hotspotLabel  = "Failed"
                ShellState.hotspot        = false
                hsLabelResetTimer.restart()
            }
        }
    }

    // Process to turn off wifi radio when restoring state
    Process {
        id: hsWifiOffProc
        command: ["bash", "-c", "nmcli radio wifi off"]
        running: false
    }

    // Stop hotspot
    Process {
        id: hsStopProc
        command: ["bash", "-c",
            "nmcli device disconnect " + hotspotRoot._hsWifiIface + " 2>/dev/null; " +
            "nmcli con delete BrainShellHotspot 2>/dev/null; true"]
        running: false
        onRunningChanged: if (!running) {
            hotspotRoot.hotspotBusy   = false
            hotspotRoot.hotspotOn     = false
            ShellState.hotspot        = false
            if (hotspotRoot._hsWifiWasOff) {
                hotspotRoot.wifiStateChanged(false)
                hsWifiOffProc.running = false
                hsWifiOffProc.running = true
                hotspotRoot._hsWifiWasOff = false
            } else {
                ShellState.wifiOn = hotspotRoot.wifiOn
                hotspotRoot.requestWifiPoll()
            }
        }
    }

    Timer {
        id: hsLabelResetTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (hotspotRoot.hotspotLabel === "Failed") hotspotRoot.hotspotLabel = ""
        }
    }

    // Ethernet disconnect watcher
    Process {
        id: hsEthernetLiveCheck
        command: ["bash", "-c",
            "nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -c 'ethernet:connected'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!hotspotRoot.hotspotOn || hotspotRoot.hotspotBusy) return
                var hasEth = parseInt(text.trim()) > 0
                if (!hasEth) {
                    hotspotRoot.hotspotLabel = "Ethernet lost"
                    hotspotRoot.hotspotBusy  = true
                    hsStopProc.command = ["bash", "-c",
                        "nmcli device disconnect " + hotspotRoot._hsWifiIface + " 2>/dev/null; " +
                        "nmcli con delete BrainShellHotspot 2>/dev/null; true"]
                    hsStopProc.running = false
                    hsStopProc.running = true
                    hsLabelResetTimer.restart()
                }
            }
        }
    }

    function _hsDoStart() {
        var ssid  = hotspotRoot._hsSSID
        var pass  = hotspotRoot._hsPassword
        var iface = hotspotRoot._hsWifiIface
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
        if (hotspotRoot.hotspotBusy) return
        if (hotspotRoot.hotspotOn) {
            hotspotRoot.hotspotBusy  = true
            hotspotRoot.hotspotLabel = ""
            hsStopProc.command = ["bash", "-c",
                "nmcli device disconnect \"" + hotspotRoot._hsWifiIface + "\" 2>/dev/null; " +
                "nmcli con delete BrainShellHotspot 2>/dev/null; true"]
            hsStopProc.running = false
            hsStopProc.running = true
        } else {
            hotspotRoot.hotspotBusy  = true
            hotspotRoot.hotspotLabel = ""
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
