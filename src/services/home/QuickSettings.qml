import QtQuick
import Quickshell.Io
import "../../"
import "../../components"

// Quick Settings — 2×4 toggle grid.
//
// Functional:
//   Wi-Fi       — nmcli radio + shows SSID when connected
//   Bluetooth   — bluetoothctl power + shows device name when connected
//   Night Light — hyprsunset (start / pkill)
//   Caffeine    — systemd-inhibit sleep infinity (held process / pkill)
//   Focus Mode  — hyprctl gaps to 0, ShellState.focusMode → TopBar hides
//
// Stub (ShellState booleans):
//   Do Not Disturb, Screen Rec, Screenshot

StatCard {
    id: root
    padding: 0

    // ── WiFi ──────────────────────────────────────────────────────────────────
    property bool   wifiOn:   false
    property string wifiSSID: ""

    Process {
        id: wifiRadioRead
        command: ["bash", "-c", "nmcli radio wifi"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.wifiOn = line.trim() === "enabled" }
        }
    }
    Process {
        id: wifiSSIDRead
        command: ["bash", "-c",
            "nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | head -1 | cut -d: -f2"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.wifiSSID = line.trim() }
        }
    }
    Process {
        id: wifiToggleProc
        command: []
        running: false
        onRunningChanged: if (!running) root._wifiPoll()
    }
    function _wifiPoll() {
        wifiRadioRead.running = false; wifiRadioRead.running = true
        wifiSSIDRead.running  = false; wifiSSIDRead.running  = true
    }
    function _wifiToggle() {
        wifiToggleProc.command = ["bash", "-c", "nmcli radio wifi " + (root.wifiOn ? "off" : "on")]
        wifiToggleProc.running = false; wifiToggleProc.running = true
    }

    // ── Bluetooth ─────────────────────────────────────────────────────────────
    property bool   btOn:     false
    property string btDevice: ""

    Process {
        id: btPowerRead
        command: ["bash", "-c",
            "bluetoothctl show 2>/dev/null | grep '^\\s*Powered:' | awk '{print $2}'"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.btOn = line.trim() === "yes" }
        }
    }
    Process {
        id: btDeviceRead
        command: ["bash", "-c",
            "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.btDevice = line.trim() }
        }
    }
    Process {
        id: btToggleProc
        command: []
        running: false
        onRunningChanged: if (!running) root._btPoll()
    }
    function _btPoll() {
        btPowerRead.running  = false; btPowerRead.running  = true
        btDeviceRead.running = false; btDeviceRead.running = true
    }
    function _btToggle() {
        btToggleProc.command = ["bash", "-c", "bluetoothctl power " + (root.btOn ? "off" : "on")]
        btToggleProc.running = false; btToggleProc.running = true
    }

    // ── Night Light (hyprsunset) ──────────────────────────────────────────────
    property bool nightLightOn: false

    Process {
        id: nlCheck
        command: ["bash", "-c", "pgrep -x hyprsunset"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { if (line.trim() !== "") root.nightLightOn = true }
        }
    }
    Process { id: nlProc;  command: ["hyprsunset"]; running: false }
    Process { id: nlKill;  command: ["bash", "-c", "pkill hyprsunset"]; running: false }

    function _nightLightToggle() {
        if (root.nightLightOn) {
            nlProc.running = false
            nlKill.running = false; nlKill.running = true
            root.nightLightOn = false
        } else {
            nlProc.running = true
            root.nightLightOn = true
        }
    }

    // ── Caffeine (systemd-inhibit) ────────────────────────────────────────────
    // Holds an idle+sleep inhibitor lock while the process is alive.
    // pgrep on load so toggling off from a previous session works correctly.

    property bool caffeineOn: false

    Process {
        id: caffeineCheck
        command: ["bash", "-c", "pgrep -f 'systemd-inhibit.*Caffeine'"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { if (line.trim() !== "") root.caffeineOn = true }
        }
    }
    // Held process — stays alive as long as caffeine is on
    Process {
        id: caffeineProc
        command: ["systemd-inhibit",
                  "--what=idle:sleep",
                  "--who=Brain Shell",
                  "--why=Caffeine mode",
                  "sleep", "infinity"]
        running: false
    }
    Process {
        id: caffeineKill
        command: ["bash", "-c", "pkill -f 'systemd-inhibit.*Caffeine'"]
        running: false
        onRunningChanged: if (!running) root.caffeineOn = false
    }

    function _caffeineToggle() {
        if (root.caffeineOn) {
            caffeineProc.running = false
            caffeineKill.running = false; caffeineKill.running = true
        } else {
            caffeineProc.running = true
            root.caffeineOn = true
        }
    }

    // ── Focus Mode (gaps + bar) ───────────────────────────────────────────────
    // On:  gaps_in/gaps_out → 0, ShellState.focusMode = true  → TopBar hides
    // Off: restore gaps,       ShellState.focusMode = false → TopBar shows

    // Store the pre-focus gap values so we can restore them exactly
    property int _savedGapsIn:  5
    property int _savedGapsOut: 10

    // Read current gap values before zeroing them
    Process {
        id: readGapsIn
        command: ["bash", "-c", "hyprctl getoption general:gaps_in -j | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('int',5))\""]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var v = parseInt(line.trim())
                if (!isNaN(v)) root._savedGapsIn = v
            }
        }
        onRunningChanged: if (!running) readGapsOut.running = true
    }
    Process {
        id: readGapsOut
        command: ["bash", "-c", "hyprctl getoption general:gaps_out -j | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('int',10))\""]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var v = parseInt(line.trim())
                if (!isNaN(v)) root._savedGapsOut = v
            }
        }
        // After reading both, apply the focus gaps
        onRunningChanged: if (!running) applyFocusGaps.running = true
    }
    Process {
        id: applyFocusGaps
        command: ["bash", "-c",
            "hyprctl keyword general:gaps_in 0 && hyprctl keyword general:gaps_out 0"]
        running: false
        onRunningChanged: if (!running) ShellState.focusMode = true
    }
    Process {
        id: restoreGaps
        command: []
        running: false
        onRunningChanged: if (!running) ShellState.focusMode = false
    }

    function _focusToggle() {
        if (ShellState.focusMode) {
            // Restore saved gaps
            restoreGaps.command = ["bash", "-c",
                "hyprctl keyword general:gaps_in "  + root._savedGapsIn  +
                " && hyprctl keyword general:gaps_out " + root._savedGapsOut]
            restoreGaps.running = false; restoreGaps.running = true
        } else {
            // Read current gaps, then zero them (chained via onRunningChanged above)
            readGapsIn.running = false; readGapsIn.running = true
        }
    }

    // ── Polling timer ─────────────────────────────────────────────────────────
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: { root._wifiPoll(); root._btPoll() }
    }

    Component.onCompleted: {
        _wifiPoll()
        _btPoll()
        nlCheck.running      = true
        caffeineCheck.running = true
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    Item {
        anchors { fill: parent; margins: 12 }

        Text {
            id: lbl
            anchors { left: parent.left; top: parent.top }
            text: "QUICK SETTINGS"; font.pixelSize: 9; font.weight: Font.Bold
            color: Qt.rgba(166/255,208/255,247/255,0.35)
        }

        Grid {
            id: grid
            anchors {
                left: parent.left; right: parent.right
                top: lbl.bottom; topMargin: 8; bottom: parent.bottom
            }
            columns: 2; rows: 4; spacing: 6

            readonly property real btnW: (width  - spacing)     / 2
            readonly property real btnH: (height - spacing * 3) / 4

            component TglBtn: Rectangle {
                id: btn
                required property bool   on
                required property string icon
                required property string label
                property  string sublabel: ""
                signal toggled()

                width: grid.btnW; height: grid.btnH; radius: 10
                color: on ? Qt.rgba(166/255,208/255,247/255,0.1)
                       : bH.hovered ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03)
                border.color: on ? Qt.rgba(166/255,208/255,247/255,0.2) : Qt.rgba(1,1,1,0.07)
                border.width: 1
                Behavior on color        { ColorAnimation { duration: 130 } }
                Behavior on border.color { ColorAnimation { duration: 130 } }

                Rectangle {
                    anchors { top: parent.top; right: parent.right; margins: 8 }
                    width: 6; height: 6; radius: 3
                    color: btn.on ? Theme.active : Qt.rgba(1,1,1,0.15)
                    Behavior on color { ColorAnimation { duration: 130 } }
                }

                Column {
                    anchors { left: parent.left; bottom: parent.bottom; margins: 9 }
                    spacing: 2
                    Text {
                        text: btn.icon; font.pixelSize: 17
                        color: btn.on ? Theme.active : Qt.rgba(1,1,1,0.28)
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }
                    Text {
                        text: btn.label; font.pixelSize: 9; font.weight: Font.Medium
                        color: btn.on ? Qt.rgba(205/255,214/255,244/255,0.9)
                                      : Qt.rgba(205/255,214/255,244/255,0.35)
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }
                    Text {
                        visible: btn.sublabel !== ""
                        text:    btn.sublabel
                        font.pixelSize: 8; font.family: "JetBrains Mono"
                        color: Qt.rgba(166/255,208/255,247/255,0.55)
                        width: btn.width - 18; elide: Text.ElideRight
                    }
                }

                HoverHandler { id: bH; cursorShape: Qt.PointingHandCursor }
                MouseArea    { anchors.fill: parent; onClicked: btn.toggled() }
            }

            TglBtn {
                on: root.wifiOn; icon: root.wifiOn ? "󰤨" : "󰤭"; label: "Wi-Fi"
                sublabel: root.wifiOn && root.wifiSSID !== "" ? root.wifiSSID : ""
                onToggled: root._wifiToggle()
            }
            TglBtn {
                on: root.btOn; icon: root.btOn ? "󰂱" : "󰂲"; label: "Bluetooth"
                sublabel: root.btOn && root.btDevice !== "" ? root.btDevice : ""
                onToggled: root._btToggle()
            }
            TglBtn {
                on: root.nightLightOn; icon: "󰖐"; label: "Night Light"
                onToggled: root._nightLightToggle()
            }
            TglBtn {
                on: root.caffeineOn; icon: "󰅶"; label: "Caffeine"
                onToggled: root._caffeineToggle()
            }
            TglBtn {
                on: ShellState.focusMode; icon: ShellState.focusMode ? "󱃕" : "󰍻"
                label: "Focus Mode"
                onToggled: root._focusToggle()
            }
            TglBtn {
                on: ShellState.dnd; icon: ShellState.dnd ? "󰂛" : "󰂚"; label: "Do Not Disturb"
                onToggled: ShellState.dnd = !ShellState.dnd
            }
            TglBtn {
                on: ShellState.screenRecord; icon: "󰻂"; label: "Screen Rec"
                onToggled: ShellState.screenRecord = !ShellState.screenRecord
            }
            TglBtn {
                on: false; icon: "󰹑"; label: "Screenshot"
                onToggled: { /* TODO */ }
            }
        }
    }
}
