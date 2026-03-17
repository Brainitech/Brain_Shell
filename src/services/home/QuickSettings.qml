import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../../"
import "../../components"

// Right column — brightness slider + scrollable quick-settings grid.
//
// Functional tiles:
//   Wi-Fi        nmcli radio wifi on/off          — SSID sublabel
//   Bluetooth    bluetoothctl power on/off         — device sublabel
//   Night Light  hyprsunset start/pkill
//   Caffeine     systemd-inhibit sleep infinity
//   Focus Mode   hyprctl gaps → 0 / restore
//   Do Not Disturb  ShellState.dnd → NotificationService suppresses incoming
//   Hotspot      nmcli device wifi hotspot / con down
//   Airplane     rfkill block all / rfkill unblock all
//
// Stub tiles (no backend yet):
//   Screen Rec, Screenshot

StatCard {
    id: root
    padding: 0

    // ─────────────────────────────────────────────────────────────────────────
    //  Brightness
    // ─────────────────────────────────────────────────────────────────────────
    property real _brightVal:  0.72
    property int  _brightMax:  100
    property bool _brightBusy: false

    Process {
        id: brightRead; command: ["bash", "-c", "brightnessctl -m"]; running: false
        stdout: SplitParser {
            onRead: function(line) {
                var p = line.split(",")
                if (p.length >= 5) {
                    var cur = parseInt(p[2]); var max = parseInt(p[4])
                    if (max > 0) { root._brightMax = max; root._brightVal = cur / max }
                }
            }
        }
    }
    Process {
        id: brightWrite
        command: ["bash", "-c", "brightnessctl set " +
            (Math.round(root._brightVal * root._brightMax) <= 0
             ? 2 : Math.round(root._brightVal * root._brightMax))]
        running: false
        onRunningChanged: if (!running) root._brightBusy = false
    }
    Timer { id: brightDebounce; interval: 50; repeat: false
        onTriggered: { root._brightBusy = true; brightWrite.running = true } }
    Timer { interval: 1000; running: true; repeat: true
        onTriggered: if (!root._brightBusy) brightRead.running = true }
    function _setBright(v) {
        root._brightVal = Math.max(0.0, Math.min(1.0, v))
        brightDebounce.restart()
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Wi-Fi
    // ─────────────────────────────────────────────────────────────────────────
    property bool   wifiOn:   false
    property string wifiSSID: ""

    Process { id: wifiRadioRead; command: ["bash", "-c", "nmcli radio wifi"]; running: false
        stdout: SplitParser { onRead: function(l) { root.wifiOn = l.trim() === "enabled" } } }
    Process { id: wifiSSIDRead
        command: ["bash", "-c",
            "nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | head -1 | cut -d: -f2"]
        running: false
        stdout: SplitParser { onRead: function(l) { root.wifiSSID = l.trim() } } }
    Process { id: wifiToggleProc; command: []; running: false
        onRunningChanged: if (!running) _wifiPoll() }
    function _wifiPoll() {
        wifiRadioRead.running = false; wifiRadioRead.running = true
        wifiSSIDRead.running  = false; wifiSSIDRead.running  = true
    }
    function _wifiToggle() {
        wifiToggleProc.command = ["bash", "-c",
            "nmcli radio wifi " + (root.wifiOn ? "off" : "on")]
        wifiToggleProc.running = false; wifiToggleProc.running = true
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Bluetooth
    // ─────────────────────────────────────────────────────────────────────────
    property bool   btOn:     false
    property string btDevice: ""

    Process { id: btPowerRead
        command: ["bash", "-c",
            "bluetoothctl show 2>/dev/null | grep '^\\s*Powered:' | awk '{print $2}'"]
        running: false
        stdout: SplitParser { onRead: function(l) { root.btOn = l.trim() === "yes" } } }
    Process { id: btDeviceRead
        command: ["bash", "-c",
            "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-"]
        running: false
        stdout: SplitParser { onRead: function(l) { root.btDevice = l.trim() } } }
    Process { id: btToggleProc; command: []; running: false
        onRunningChanged: if (!running) _btPoll() }
    function _btPoll() {
        btPowerRead.running  = false; btPowerRead.running  = true
        btDeviceRead.running = false; btDeviceRead.running = true
    }
    function _btToggle() {
        btToggleProc.command = ["bash", "-c",
            "bluetoothctl power " + (root.btOn ? "off" : "on")]
        btToggleProc.running = false; btToggleProc.running = true
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Night Light  (hyprsunset)
    // ─────────────────────────────────────────────────────────────────────────
    property bool nightLightOn: false

    Process { id: nlCheck; command: ["bash", "-c", "pgrep -x hyprsunset"]; running: false
        stdout: SplitParser { onRead: function(l) { if (l.trim() !== "") root.nightLightOn = true } } }
    Process { id: nlProc; command: ["hyprsunset", "-t", "5600"]; running: false }
    Process { id: nlKill; command: ["bash", "-c", "pkill hyprsunset"]; running: false }
    function _nightLightToggle() {
        if (root.nightLightOn) {
            nlProc.running = false; nlKill.running = false; nlKill.running = true
            root.nightLightOn = false
        } else { nlProc.running = true; root.nightLightOn = true }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Caffeine  (systemd-inhibit)
    // ─────────────────────────────────────────────────────────────────────────
    property bool caffeineOn: false

    Process { id: caffeineCheck
        command: ["bash", "-c", "pgrep -f 'systemd-inhibit.*Caffeine'"]; running: false
        stdout: SplitParser { onRead: function(l) { if (l.trim() !== "") root.caffeineOn = true } } }
    Process { id: caffeineProc
        command: ["systemd-inhibit","--what=idle:sleep",
                  "--who=Brain Shell","--why=Caffeine mode","sleep","infinity"]
        running: false }
    Process { id: caffeineKill
        command: ["bash", "-c", "pkill -f 'systemd-inhibit.*Caffeine'"]; running: false
        onRunningChanged: if (!running) root.caffeineOn = false }
    function _caffeineToggle() {
        if (root.caffeineOn) {
            caffeineProc.running = false
            caffeineKill.running = false; caffeineKill.running = true
        } else { caffeineProc.running = true; root.caffeineOn = true }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Do Not Disturb
    //  Toggling on also dismisses all current notifications immediately.
    // ─────────────────────────────────────────────────────────────────────────
    function _dndToggle() {
        ShellState.dnd = !ShellState.dnd
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Dark Mode  (stub — backend wired later)
    // ─────────────────────────────────────────────────────────────────────────
    property bool darkModeOn: true

    function _darkModeToggle() {
        darkModeOn = !darkModeOn
        // TODO: wire backend
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Hotspot  (nmcli)
    //  Creates a hotspot on first enable; subsequent toggles up/down by name.
    // ─────────────────────────────────────────────────────────────────────────
    property bool   hotspotOn:   false
    property string hotspotSSID: ""   // name of the active hotspot connection

    Process { id: hotspotCheck
        command: ["bash", "-c",
            "nmcli -t -f NAME,TYPE,STATE con show --active 2>/dev/null" +
            " | grep ':802-11-wireless:' | grep -i hotspot | head -1 | cut -d: -f1"]
        running: false
        stdout: SplitParser {
            onRead: function(l) {
                var n = l.trim()
                root.hotspotOn   = n !== ""
                root.hotspotSSID = n
            }
        }
    }
    Process { id: hotspotUp
        // Start hotspot — uses existing "Hotspot" connection if present,
        // otherwise nmcli creates one automatically
        command: ["bash", "-c", "nmcli device wifi hotspot 2>/dev/null || nmcli con up Hotspot"]
        running: false
        onRunningChanged: if (!running) hotspotCheck.running = true }
    Process { id: hotspotDown; command: []; running: false
        onRunningChanged: if (!running) {
            root.hotspotOn = false; root.hotspotSSID = ""
        }
    }
    function _hotspotToggle() {
        if (root.hotspotOn) {
            var name = root.hotspotSSID !== "" ? root.hotspotSSID : "Hotspot"
            hotspotDown.command = ["bash", "-c", "nmcli con down '" + name + "'"]
            hotspotDown.running = false; hotspotDown.running = true
        } else {
            hotspotUp.running = false; hotspotUp.running = true
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Airplane Mode  (rfkill)
    // ─────────────────────────────────────────────────────────────────────────
    property bool airplaneOn: false

    Process { id: airplaneCheck
        command: ["bash", "-c",
            "rfkill list wifi 2>/dev/null | grep -c 'Soft blocked: yes'"]
        running: false
        stdout: SplitParser {
            onRead: function(l) { root.airplaneOn = parseInt(l.trim()) > 0 }
        }
    }
    Process { id: airplaneOn_proc
        command: ["bash", "-c", "rfkill block all"]; running: false
        onRunningChanged: if (!running) root.airplaneOn = true }
    Process { id: airplaneOff_proc
        command: ["bash", "-c", "rfkill unblock all"]; running: false
        onRunningChanged: if (!running) root.airplaneOn = false }
    function _airplaneToggle() {
        if (root.airplaneOn) {
            airplaneOff_proc.running = false; airplaneOff_proc.running = true
        } else {
            airplaneOn_proc.running = false; airplaneOn_proc.running = true
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Focus Mode  (hyprctl gaps)
    // ─────────────────────────────────────────────────────────────────────────
    property int _savedGapsIn: 5; property int _savedGapsOut: 10

    Process { id: readGapsIn
        command: ["bash", "-c",
            "hyprctl getoption general:gaps_in -j | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('int',5))\""]
        running: false
        stdout: SplitParser { onRead: function(l) { var v=parseInt(l.trim()); if(!isNaN(v)) root._savedGapsIn=v } }
        onRunningChanged: if (!running) readGapsOut.running = true }
    Process { id: readGapsOut
        command: ["bash", "-c",
            "hyprctl getoption general:gaps_out -j | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('int',10))\""]
        running: false
        stdout: SplitParser { onRead: function(l) { var v=parseInt(l.trim()); if(!isNaN(v)) root._savedGapsOut=v } }
        onRunningChanged: if (!running) applyFocusGaps.running = true }
    Process { id: applyFocusGaps
        command: ["bash", "-c",
            "hyprctl keyword general:gaps_in 0 && hyprctl keyword general:gaps_out 10"]
        running: false; onRunningChanged: if (!running) ShellState.focusMode = true }
    Process { id: restoreGaps; command: []; running: false
        onRunningChanged: if (!running) ShellState.focusMode = false }
    function _focusToggle() {
        if (ShellState.focusMode) {
            restoreGaps.command = ["bash", "-c",
                "hyprctl keyword general:gaps_in "  + root._savedGapsIn  +
                " && hyprctl keyword general:gaps_out " + root._savedGapsOut]
            restoreGaps.running = false; restoreGaps.running = true
        } else { readGapsIn.running = false; readGapsIn.running = true }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Polling timer
    // ─────────────────────────────────────────────────────────────────────────
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: {
            _wifiPoll(); _btPoll()
            hotspotCheck.running = false; hotspotCheck.running = true
            airplaneCheck.running = false; airplaneCheck.running = true
        }
    }

    Component.onCompleted: {
        brightRead.running    = true
        _wifiPoll(); _btPoll()
        nlCheck.running       = true
        caffeineCheck.running = true
        hotspotCheck.running  = true
        airplaneCheck.running = true
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  UI
    // ─────────────────────────────────────────────────────────────────────────
    Column {
        anchors { fill: parent; margins: 12 }
        spacing: 0

        // Brightness section
        Item {
            width: parent.width
            height: 52

            Text {
                id: brightLbl
                anchors { left: parent.left; top: parent.top }
                text: "BRIGHTNESS"; font.pixelSize: 9; font.weight: Font.Bold
                color: Qt.rgba(166/255,208/255,247/255,0.35)
            }
            Text {
                anchors { right: parent.right; top: parent.top }
                text: Math.round(root._brightVal * 100) + "%"
                font.pixelSize: 9; font.family: "JetBrains Mono"; font.weight: Font.Bold
                color: Qt.rgba(166/255,208/255,247/255,0.6)
            }

            Row {
                anchors { left: parent.left; right: parent.right; top: brightLbl.bottom; topMargin: 8 }
                spacing: 8

                Text { anchors.verticalCenter: parent.verticalCenter
                    text: "󰃞"; font.pixelSize: 13; color: Qt.rgba(1,1,1,0.28) }

                Item {
                    id: btw
                    width: parent.width - 13 - 13 - parent.spacing * 2
                    height: 20; anchors.verticalCenter: parent.verticalCenter
                    readonly property int thumbD: 14

                    Rectangle {
                        id: btrack
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 5; radius: height / 2
                        color: Qt.rgba(1,1,1,0.08)
                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: Math.max(parent.radius * 2, parent.width * root._brightVal)
                            radius: parent.radius; color: Theme.active
                            Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                            function _c(mx) {
                                return Math.max(0.0, Math.min(1.0,
                                    (mx - btw.thumbD/2) / (btrack.width - btw.thumbD)))
                            }
                            onPressed:         root._setBright(_c(mouseX))
                            onPositionChanged: if (pressed) root._setBright(_c(mouseX))
                        }
                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: function(e) {
                                root._setBright(root._brightVal + (e.angleDelta.y > 0 ? 0.05 : -0.05))
                            }
                        }
                    }
                    Rectangle {
                        width: btw.thumbD; height: btw.thumbD; radius: btw.thumbD / 2
                        color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(btw.width - width, root._brightVal * (btw.width - width)))
                        Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                    }
                }

                Text { anchors.verticalCenter: parent.verticalCenter
                    text: "󰃠"; font.pixelSize: 13; color: Qt.rgba(166/255,208/255,247/255,0.65) }
            }
        }

        // Divider
        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.06) }
        Item      { width: parent.width; height: 8 }

        Text {
            id: qsLbl; width: parent.width
            text: "QUICK SETTINGS"; font.pixelSize: 9; font.weight: Font.Bold
            color: Qt.rgba(166/255,208/255,247/255,0.35)
        }
        Item { width: parent.width; height: 8 }

        // Scrollable grid
        Item {
            width:  parent.width
            height: root.height - 12 - 52 - 1 - 8 - qsLbl.height -8

            Flickable {
                id: flick
                anchors.fill:   parent
                contentWidth:   width
                contentHeight:  tileGrid.implicitHeight +8
                clip:           true
                boundsBehavior: Flickable.StopAtBounds

                // ── Toggle button component ───────────────────────────────────
                component TglBtn: Rectangle {
                    id: btn
                    required property bool   on
                    required property string icon
                    required property string label
                    property  string sublabel: ""
                    signal toggled()

                    radius: 10
                    color: on ? Qt.rgba(166/255,208/255,247/255,0.10)
                           : bH.hovered ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03)
                    border.color: on ? Qt.rgba(166/255,208/255,247/255,0.22) : Qt.rgba(1,1,1,0.07)
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

                Grid {
                    id: tileGrid
                    width: flick.width
                    columns: 2; spacing: 6

                    readonly property real btnW: (width - spacing) / 2
                    readonly property real btnH: btnW * 0.85

                    TglBtn {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        on: root.wifiOn; icon: root.wifiOn ? "󰤨" : "󰤭"; label: "Wi-Fi"
                        sublabel: root.wifiOn && root.wifiSSID !== "" ? root.wifiSSID : ""
                        onToggled: root._wifiToggle()
                    }
                    TglBtn {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        on: root.btOn; icon: root.btOn ? "󰂱" : "󰂲"; label: "Bluetooth"
                        sublabel: root.btOn && root.btDevice !== "" ? root.btDevice : ""
                        onToggled: root._btToggle()
                    }
                    TglBtn {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        on: root.airplaneOn; icon: "󰀝"; label: "Airplane Mode"
                        onToggled: root._airplaneToggle()
                    }
                    TglBtn {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        on: root.hotspotOn; icon: "󰀃"; label: "Hotspot"
                        sublabel: root.hotspotOn && root.hotspotSSID !== "" ? root.hotspotSSID : ""
                        onToggled: root._hotspotToggle()
                    }
                    TglBtn {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        on: root.nightLightOn; icon: "󰖐"; label: "Night Light"
                        onToggled: root._nightLightToggle()
                    }
                    TglBtn {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        on: root.caffeineOn; icon: "󰅶"; label: "Caffeine"
                        onToggled: root._caffeineToggle()
                    }
                    TglBtn {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        on: ShellState.focusMode
                        icon: ShellState.focusMode ? "󱃕" : "󰍻"; label: "Focus Mode"
                        onToggled: root._focusToggle()
                    }
                    TglBtn {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        on: ShellState.dnd; icon: ShellState.dnd ? "󰂛" : "󰂚"
                        label: "Do Not Disturb"
                        onToggled: root._dndToggle()
                    }
                    TglBtn {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        on: ShellState.screenRecord; icon: "󰻂"; label: "Screen Capture"
                        onToggled: ShellState.screenRecord = !ShellState.screenRecord
                    }
                    TglBtn {
                        width: tileGrid.btnW; height: tileGrid.btnH
                        on: root.darkModeOn
                        icon: root.darkModeOn ? "󰖔" : "󰖙"
                        label: root.darkModeOn ? "Dark Mode" : "Light Mode"
                        onToggled: root._darkModeToggle()
                    }
                }
            }
        }
    }
}
