import QtQuick
import Quickshell.Io
import "../../"
import "../../components"

// Quick Settings — 2×4 toggle grid.
//
// Functional:
//   Wi-Fi      — nmcli radio + shows SSID when connected
//   Bluetooth  — bluetoothctl power + shows device name when connected
//   Night Light— hyprsunset (start/pkill)
//
// Stub (ShellState booleans):
//   Caffeine, Do Not Disturb, Game Mode, Screen Rec, Screenshot

StatCard {
    id: root
    padding: 0

    // ── WiFi state ────────────────────────────────────────────────────────────
    property bool   wifiOn:   false
    property string wifiSSID: ""        // "" when not connected

    // ── Bluetooth state ───────────────────────────────────────────────────────
    property bool   btOn:     false
    property string btDevice: ""        // "" when no device connected

    // ── Night Light state ─────────────────────────────────────────────────────
    property bool nightLightOn: false

    // ─────────────────────────────────────────────────────────────────────────
    //  WiFi processes
    // ─────────────────────────────────────────────────────────────────────────

    // Check radio state: "enabled" or "disabled"
    Process {
        id: wifiRadioRead
        command: ["bash", "-c", "nmcli radio wifi"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                root.wifiOn = line.trim() === "enabled"
            }
        }
    }

    // Get connected SSID (empty output = not connected)
    Process {
        id: wifiSSIDRead
        command: ["bash", "-c",
            "nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | head -1 | cut -d: -f2"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.wifiSSID = line.trim() }
        }
    }

    // Toggle wifi radio on/off
    Process {
        id: wifiToggle
        command: []
        running: false
        onRunningChanged: if (!running) wifiPoll()
    }

    function wifiPoll() {
        wifiRadioRead.running = false; wifiRadioRead.running = true
        wifiSSIDRead.running  = false; wifiSSIDRead.running  = true
    }

    function wifiToggleFn() {
        wifiToggle.command = ["bash", "-c",
            "nmcli radio wifi " + (root.wifiOn ? "off" : "on")]
        wifiToggle.running = false
        wifiToggle.running = true
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Bluetooth processes
    // ─────────────────────────────────────────────────────────────────────────

    // Check power state: "yes" or "no"
    Process {
        id: btPowerRead
        command: ["bash", "-c",
            "bluetoothctl show 2>/dev/null | grep '^\\s*Powered:' | awk '{print $2}'"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.btOn = line.trim() === "yes" }
        }
    }

    // Get connected device name (first connected device)
    Process {
        id: btDeviceRead
        command: ["bash", "-c",
            "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root.btDevice = line.trim() }
        }
    }

    // Toggle bluetooth power
    Process {
        id: btToggle
        command: []
        running: false
        onRunningChanged: if (!running) btPoll()
    }

    function btPoll() {
        btPowerRead.running  = false; btPowerRead.running  = true
        btDeviceRead.running = false; btDeviceRead.running = true
    }

    function btToggleFn() {
        btToggle.command = ["bash", "-c",
            "bluetoothctl power " + (root.btOn ? "off" : "on")]
        btToggle.running = false
        btToggle.running = true
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Night Light (hyprsunset)
    // ─────────────────────────────────────────────────────────────────────────

    // Check if hyprsunset is already running on load
    Process {
        id: nlCheck
        command: ["bash", "-c", "pgrep -x hyprsunset"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") root.nightLightOn = true
            }
        }
    }

    // hyprsunset — kept running while night light is on
    Process {
        id: nlProcess
        command: ["hyprsunset"]
        running: false
    }

    // Kill hyprsunset
    Process {
        id: nlKill
        command: ["bash", "-c", "pkill hyprsunset"]
        running: false
    }

    function nightLightToggle() {
        if (root.nightLightOn) {
            nlProcess.running = false
            nlKill.running    = false; nlKill.running = true
            root.nightLightOn = false
        } else {
            nlProcess.running = true
            root.nightLightOn = true
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Polling timer — keeps state in sync
    // ─────────────────────────────────────────────────────────────────────────
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: { root.wifiPoll(); root.btPoll() }
    }

    Component.onCompleted: {
        wifiPoll()
        btPoll()
        nlCheck.running = true
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  UI
    // ─────────────────────────────────────────────────────────────────────────
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

            // ── Toggle button ─────────────────────────────────────────────────
            component TglBtn: Rectangle {
                id: btn
                required property bool   on
                required property string icon
                required property string label
                property  string sublabel: ""   // optional — SSID, device name, etc.
                signal toggled()

                width: grid.btnW; height: grid.btnH; radius: 10
                color: on ? Qt.rgba(166/255,208/255,247/255,0.1)
                       : bH.hovered ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03)
                border.color: on ? Qt.rgba(166/255,208/255,247/255,0.2) : Qt.rgba(1,1,1,0.07)
                border.width: 1
                Behavior on color        { ColorAnimation { duration: 130 } }
                Behavior on border.color { ColorAnimation { duration: 130 } }

                // Status dot — top right
                Rectangle {
                    anchors { top: parent.top; right: parent.right; margins: 8 }
                    width: 6; height: 6; radius: 3
                    color: btn.on ? Theme.active : Qt.rgba(1,1,1,0.15)
                    Behavior on color { ColorAnimation { duration: 130 } }
                }

                // Icon + label + sublabel — bottom left
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
                    // Sublabel — device/SSID name, only shown when non-empty
                    Text {
                        visible: btn.sublabel !== ""
                        text:    btn.sublabel
                        font.pixelSize: 8; font.family: "JetBrains Mono"
                        color: Qt.rgba(166/255,208/255,247/255,0.55)
                        width: btn.width - 18
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }
                }

                HoverHandler { id: bH; cursorShape: Qt.PointingHandCursor }
                MouseArea    { anchors.fill: parent; onClicked: btn.toggled() }
            }

            // ── Tiles ──────────────────────────────────────────────────────────

            TglBtn {
                on:       root.wifiOn
                icon:     root.wifiOn ? "󰤨" : "󰤭"
                label:    "Wi-Fi"
                sublabel: root.wifiOn && root.wifiSSID !== "" ? root.wifiSSID : ""
                onToggled: root.wifiToggleFn()
            }
            TglBtn {
                on:       root.btOn
                icon:     root.btOn ? "󰂱" : "󰂲"
                label:    "Bluetooth"
                sublabel: root.btOn && root.btDevice !== "" ? root.btDevice : ""
                onToggled: root.btToggleFn()
            }
            TglBtn {
                on:       root.nightLightOn
                icon:     "󰖐"
                label:    "Night Light"
                onToggled: root.nightLightToggle()
            }
            TglBtn {
                on:       ShellState.caffeine
                icon:     "󰅶"
                label:    "Caffeine"
                onToggled: ShellState.caffeine = !ShellState.caffeine
            }
            TglBtn {
                on:       ShellState.dnd
                icon:     ShellState.dnd ? "󰂛" : "󰂚"
                label:    "Do Not Disturb"
                onToggled: ShellState.dnd = !ShellState.dnd
            }
            TglBtn {
                on:       ShellState.gameMode
                icon:     "󰊚"
                label:    "Game Mode"
                onToggled: ShellState.gameMode = !ShellState.gameMode
            }
            TglBtn {
                on:       ShellState.screenRecord
                icon:     "󰻂"
                label:    "Screen Rec"
                onToggled: ShellState.screenRecord = !ShellState.screenRecord
            }
            TglBtn {
                on:       false
                icon:     "󰹑"
                label:    "Screenshot"
                onToggled: { /* TODO */ }
            }
        }
    }
}
