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

    property var wifiPoll: Process {
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | grep '^yes:' | head -1 | cut -d: -f2"]
        running: false
        stdout: SplitParser { onRead: function(l) { var s = parseInt(l.trim()); root.signal = isNaN(s) ? 0 : s } }
    }
    property var ethPoll: Process {
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -c 'ethernet:connected'"]
        running: false
        stdout: SplitParser { onRead: function(l) { root.ethernet = parseInt(l.trim()) > 0 } }
    }
    property var connPoll: Process {
        command: ["bash", "-c", "nmcli -t -f CONNECTIVITY general 2>/dev/null | head -1"]
        running: false
        stdout: SplitParser {
            onRead: function(l) { var v = l.trim().toLowerCase(); if (v !== "") root.connectivity = v }
        }
    }
    property var btPowerPoll: Process {
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep '^\\s*Powered:' | awk '{print $2}'"]
        running: false
        stdout: SplitParser { onRead: function(l) { ShellState.btPowered = (l.trim() === "yes") } }
    }
    property var btDevPoll: Process {
        command: ["bash", "-c", "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-"]
        running: false
        stdout: SplitParser { onRead: function(l) { ShellState.btConnected = (l.trim() !== "") } }
    }
    property var pollTimer: Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            root.wifiPoll.running    = true
            root.ethPoll.running     = true
            root.connPoll.running    = true
            root.btPowerPoll.running = true
            root.btDevPoll.running   = true
        }
    }
}
