import QtQuick
import Quickshell.Io
import "../"
import "../components"

// BluetoothTab — bluetooth device management.
// _btPowered tracks adapter state; overlay shows when off.
// _parseDevices writes ShellState.btPowered + btConnected on every refresh.
// Scan disabled while adapter is off.

Item {
    id: root

    property real localScale: 1.0
    property var    _allDevices:  []
    property bool   _scanning:    false
    property bool   _btPowered:   true
    property string _actionMac:   ""
    property string _removeMac:   ""
    property string _removingMac: ""
    property string _pairingMac:  ""

    readonly property var _paired: {
        var r = []
        for (var i = 0; i < _allDevices.length; i++)
            if (_allDevices[i].paired) r.push(_allDevices[i])
        return r
    }
    readonly property var _available: {
        var r = []
        for (var i = 0; i < _allDevices.length; i++)
            if (!_allDevices[i].paired) r.push(_allDevices[i])
        return r
    }

    function _iconFromName(name) {
        var n = name.toLowerCase()
        if (n.match(/head(phone|set)|earphone|earpad|airpod|buds|wf-|wh-|ep-|tws/)) return "headphone"
        if (n.match(/speaker|soundbar|boom|jbl|bose|harman|charge|flip|pulse/))      return "speaker"
        if (n.match(/keyboard|kbd/))                                                   return "keyboard"
        if (n.match(/mouse|trackpad|trackball|mx master|mx anywhere/))                return "mouse"
        if (n.match(/phone|iphone|android|galaxy|pixel|oneplus|xperia|redmi/))        return "phone"
        if (n.match(/macbook|laptop|thinkpad|xps|zenbook|surface/))                   return "laptop"
        if (n.match(/watch|band|garmin|fitbit|amazfit|mi band|polar/))                return "watch"
        if (n.match(/controller|gamepad|dualshock|dualsense|xbox|joycon|steam/))      return "gamepad"
        if (n.match(/tv |television|bravia|smart-tv/))                                 return "tv"
        return "default"
    }

    function _glyph(t) {
        switch(t){
            case "headphone": return "󰋋"
            case "speaker":   return "󰓃"
            case "keyboard":  return "󰌌"
            case "mouse":     return "󰍽"
            case "phone":     return "󰄜"
            case "laptop":    return "󰌢"
            case "watch":     return "󰢗"
            case "gamepad":   return "󰊖"
            case "tv":        return "󰔮"
            default:          return "󰂯"
        }
    }

    Connections {
        target: Popups
        function onNetworkOpenChanged() {
            if (Popups.networkOpen && root.visible) {
                root._pairingMac  = ""
                root._removeMac   = ""
                root._removingMac = ""
                root._actionMac   = ""
                root._loadDevices()
            }
        }
    }

    // List query — includes POWERED check
    Process {
        id: listProc
        command: [
            "bash", "-c",
            "echo 'POWERED:'; " +
            "bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}'; " +
            "echo 'PAIRED:'; " +
            "bluetoothctl devices Paired    2>/dev/null | awk '{print $2}'; " +
            "echo 'CONNECTED:'; " +
            "bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'; " +
            "echo 'ALL:'; " +
            "bluetoothctl devices           2>/dev/null"
        ]
        running: false
        stdout: StdioCollector { onStreamFinished: root._parseDevices(text) }
    }

    // Scan — pipe commands into interactive bluetoothctl
    Process {
        id: scanProc
        command: [
            "bash", "-c",
            "trap 'echo scan off | bluetoothctl 2>/dev/null' EXIT; " +
            "(echo 'power on'; echo 'scan on'; sleep 8) | timeout 9 bluetoothctl 2>/dev/null"
        ]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var m = line.match(/\[NEW\]\s+Device\s+([0-9A-Fa-f:]{17})\s+(.+)/)
                if (!m) return
                var mac = m[1]; var name = m[2].trim()
                var devs = root._allDevices.slice()
                for (var i = 0; i < devs.length; i++) if (devs[i].mac === mac) return
                devs.push({ mac: mac, name: name, paired: false, connected: false, iconType: root._iconFromName(name) })
                root._allDevices = devs
            }
        }
        onRunningChanged: if (!running) { root._scanning = false; scanPollTimer.stop(); root._loadDevices() }
    }

    Timer { id: scanPollTimer; interval: 2000; repeat: true; running: false; onTriggered: root._loadDevices() }

    Process {
        id: actionProc
        command: []
        running: false
        onRunningChanged: if (!running) { root._actionMac = ""; root._loadDevices() }
    }

    Process {
        id: removeProc
        command: []
        running: false
        onRunningChanged: if (!running) { root._removingMac = ""; root._loadDevices() }
    }

    Process {
        id: powerProc
        command: []
        running: false
        onRunningChanged: if (!running) root._loadDevices()
    }

    Process { id: bluemanProc; command: ["blueman-manager"]; running: false }

    Timer { interval: 8000; repeat: true; running: true; onTriggered: if (!root._scanning) root._loadDevices() }

    function _loadDevices() {
        if (listProc.running) return
        listProc.running = false
        listProc.running = true
    }

    function _parseDevices(raw) {
        var lines = raw.split("\n")
        var mode = ""; var paired = {}; var conn = {}; var known = {}

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === "POWERED:")   { mode = "powered";   continue }
            if (line === "PAIRED:")    { mode = "paired";    continue }
            if (line === "CONNECTED:") { mode = "connected"; continue }
            if (line === "ALL:")       { mode = "all";       continue }
            if (line === "")           continue

            if (mode === "powered") {
                var p = line.toLowerCase() === "yes"
                root._btPowered      = p
                ShellState.btPowered = p
                continue
            }
            if (mode === "paired")    { paired[line] = true; continue }
            if (mode === "connected") { conn[line]   = true; continue }
            if (mode === "all") {
                var parts = line.split(" ")
                if (parts.length < 3 || parts[0] !== "Device") continue
                var mac = parts[1]; var name = parts.slice(2).join(" ")
                if (mac && name) known[mac] = name
            }
        }

        ShellState.btConnected = Object.keys(conn).length > 0

        var seenMac = {}; var devs = []
        for (var mac in known) {
            if (seenMac[mac]) continue
            seenMac[mac] = true
            devs.push({ mac: mac, name: known[mac], paired: !!paired[mac], connected: !!conn[mac], iconType: root._iconFromName(known[mac]) })
        }
        var existing = root._allDevices
        for (var j = 0; j < existing.length; j++) {
            var d = existing[j]
            if (seenMac[d.mac]) continue
            seenMac[d.mac] = true
            devs.push({ mac: d.mac, name: d.name, paired: !!paired[d.mac], connected: !!conn[d.mac], iconType: d.iconType })
        }
        root._allDevices = devs
    }

    function _setPower(on) {
        root._btPowered       = on
        ShellState.btPowered  = on
        if (!on) { ShellState.btConnected = false; root._allDevices = [] }
        powerProc.command = ["bluetoothctl", "power", on ? "on" : "off"]
        powerProc.running = false
        powerProc.running = true
    }

    function _startScan() {
        if (!root._btPowered) return
        if (root._scanning) {
            root._scanning = false
            scanProc.running = false
            scanPollTimer.stop()
            root._loadDevices()
            return
        }
        root._scanning = true
        scanProc.running = false
        scanProc.running = true
        scanPollTimer.restart()
    }

    function _connect(mac) {
        root._actionMac = mac
        root._pairingMac = ""
        actionProc.command = ["bluetoothctl", "connect", mac]
        actionProc.running = false; actionProc.running = true
    }

    function _disconnect(mac) {
        root._actionMac = mac
        actionProc.command = ["bluetoothctl", "disconnect", mac]
        actionProc.running = false; actionProc.running = true
    }

    function _pair(mac, pin) {
        root._actionMac = mac; root._pairingMac = ""
        actionProc.command = pin !== ""
            ? ["bash", "-c",
                "(echo 'default-agent'; echo 'trust " + mac + "'; echo 'pair " + mac + "'; sleep 1; echo '" + pin + "'; sleep 4) | timeout 12 bluetoothctl 2>/dev/null"]
            : ["bash", "-c",
                "(echo 'default-agent'; echo 'trust " + mac + "'; echo 'pair " + mac + "'; sleep 1; echo 'yes'; sleep 4) | timeout 12 bluetoothctl 2>/dev/null"]
        actionProc.running = false; actionProc.running = true
    }

    function _remove(mac) {
        root._removeMac = ""; root._removingMac = mac
        removeProc.command = ["bash", "-c",
            "bluetoothctl untrust " + mac + " 2>/dev/null; " +
            "bluetoothctl disconnect " + mac + " 2>/dev/null; " +
            "bluetoothctl remove " + mac + " 2>/dev/null"]
        removeProc.running = false; removeProc.running = true
    }

    Component.onCompleted: _loadDevices()

    // ── Scan rings ────────────────────────────────────────────────────────────
    component ScanRings: Item {
        id: ringsRoot
        property string centerGlyph: "󰂯"
        property int    glyphSize:   Math.round(18 * localScale)
        Repeater {
            model: 4
            delegate: Rectangle {
                required property int index
                anchors.centerIn: parent
                width: ringsRoot.width; height: ringsRoot.width; radius: ringsRoot.width / 2
                color: "transparent"
                border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.80)
                border.width: Math.max(1, Math.round(1.5 * localScale)); opacity: 0; scale: 0.08
                SequentialAnimation {
                    running: root._scanning; loops: Animation.Infinite
                    PauseAnimation { duration: index * 650 }
                    ParallelAnimation {
                        NumberAnimation { property: "scale";   from: 0.08; to: 1.0; duration: 2200; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "opacity"; from: 0.80; to: 0.0; duration: 2200; easing.type: Easing.OutQuad  }
                    }
                }
            }
        }
        Text {
            anchors.centerIn: parent; text: ringsRoot.centerGlyph; font.pixelSize: ringsRoot.glyphSize
            color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)
            SequentialAnimation on opacity {
                running: root._scanning; loops: Animation.Infinite
                NumberAnimation { to: 0.20; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.80; duration: 700; easing.type: Easing.InOutSine }
            }
        }
    }

    // ── Device row ────────────────────────────────────────────────────────────
    component DeviceRow: Item {
        id: dRow
        required property var  device
        required property bool isPaired

        readonly property bool isConnected:     device.connected
        readonly property bool inAction:        root._actionMac   === device.mac
        readonly property bool inRemove:        root._removingMac === device.mac
        readonly property bool isPairingOpen:   root._pairingMac  === device.mac
        readonly property bool isRemovePending: root._removeMac   === device.mac

        width: parent?.width ?? 0
        height: baseRow.height + expandArea.height

        Rectangle {
            anchors.fill: parent; radius: Math.round(Theme.cornerRadius * localScale)
            color: dRow.isConnected
                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
                : rowHov.hovered && !dRow.isPaired ? Qt.rgba(1,1,1,0.04) : "transparent"
            border.color: dRow.isConnected
                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                : dRow.isRemovePending ? Qt.rgba(248/255,113/255,113/255,0.22) : Qt.rgba(1,1,1,0.06)
            border.width: Math.max(1, Math.round(1 * localScale))
            Behavior on color        { ColorAnimation { duration: 130 } }
            Behavior on border.color { ColorAnimation { duration: 130 } }
        }

        Item {
            id: baseRow
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: Math.round(50 * localScale)

            Text {
                anchors { left: parent.left; leftMargin: Math.round(12 * localScale); verticalCenter: parent.verticalCenter }
                text: root._glyph(dRow.device.iconType); font.pixelSize: Math.round(18 * localScale)
                color: dRow.isConnected ? Theme.active
                    : (dRow.inAction || dRow.inRemove) ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5) : Qt.rgba(1,1,1,0.32)
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Column {
                anchors { left: parent.left; leftMargin: Math.round(44 * localScale); verticalCenter: parent.verticalCenter }
                spacing: Math.round(3 * localScale)
                Text {
                    text: dRow.device.name; font.pixelSize: Math.round(13 * localScale)
                    font.weight: dRow.isConnected ? Font.Medium : Font.Normal
                    color: dRow.isConnected ? Theme.text : Qt.rgba(1,1,1,0.68)
                    width: Math.round(160 * localScale); elide: Text.ElideRight
                }
                Text {
                    visible: dRow.isConnected || dRow.inAction || dRow.inRemove
                    text: dRow.inRemove ? "Removing…" : dRow.inAction ? "Working…" : "Connected"
                    font.pixelSize: Math.round(10 * localScale)
                    color: (dRow.inAction || dRow.inRemove) ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55) : Theme.active
                }
            }

            Row {
                anchors { right: parent.right; rightMargin: Math.round(10 * localScale); verticalCenter: parent.verticalCenter }
                spacing: Math.round(6 * localScale)

                // Spinner
                Text {
                    visible: dRow.inAction || dRow.inRemove
                    text: "○"; font.pixelSize: Math.round(15 * localScale); color: Theme.active
                    anchors.verticalCenter: parent.verticalCenter
                    SequentialAnimation on opacity {
                        running: dRow.inAction || dRow.inRemove; loops: Animation.Infinite
                        NumberAnimation { to: 0.15; duration: 450 }
                        NumberAnimation { to: 1.0;  duration: 450 }
                    }
                }

                // Paired: connect/disconnect pill
                Rectangle {
                    visible: dRow.isPaired && !dRow.inAction && !dRow.inRemove
                    anchors.verticalCenter: parent.verticalCenter
                    width: togContent.implicitWidth + Math.round(20 * localScale); height: Math.round(28 * localScale); radius: Math.round(14 * localScale)
                    color: dRow.isConnected ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14) : togH.hovered ? Qt.rgba(1,1,1,0.09) : Qt.rgba(1,1,1,0.04)
                    border.color: dRow.isConnected ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.36) : Qt.rgba(1,1,1,0.11)
                    border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        id: togContent; anchors.centerIn: parent; spacing: Math.round(7 * localScale)
                        Rectangle { width: Math.round(7 * localScale); height: Math.round(7 * localScale); radius: Math.round(4 * localScale); anchors.verticalCenter: parent.verticalCenter; color: dRow.isConnected ? Theme.active : Qt.rgba(1,1,1,0.25); Behavior on color { ColorAnimation { duration: 150 } } }
                        Text { text: dRow.isConnected ? "Connected" : "Connect"; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter; color: dRow.isConnected ? Theme.active : Qt.rgba(1,1,1,0.48); Behavior on color { ColorAnimation { duration: 120 } } }
                    }
                    HoverHandler { id: togH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: dRow.isConnected ? root._disconnect(dRow.device.mac) : root._connect(dRow.device.mac) }
                }

                // Paired: remove button
                Item {
                    visible: dRow.isPaired && !dRow.inAction && !dRow.inRemove
                    width: Math.round(28 * localScale); height: Math.round(28 * localScale); anchors.verticalCenter: parent.verticalCenter
                    Rectangle { anchors.fill: parent; radius: Math.round(7 * localScale); color: rmH.hovered ? Qt.rgba(248/255,113/255,113/255,0.20) : dRow.isRemovePending ? Qt.rgba(248/255,113/255,113/255,0.12) : "transparent"; Behavior on color { ColorAnimation { duration: 100 } } }
                    Text { anchors.centerIn: parent; text: "󰗼"; font.pixelSize: Math.round(13 * localScale); color: (rmH.hovered || dRow.isRemovePending) ? "#f87171" : Qt.rgba(1,1,1,0.25); Behavior on color { ColorAnimation { duration: 100 } } }
                    HoverHandler { id: rmH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: { root._pairingMac = ""; root._removeMac = dRow.isRemovePending ? "" : dRow.device.mac } }
                }

                // Available: Pair + PIN icon
                Row {
                    visible: !dRow.isPaired && !dRow.inAction
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.round(6 * localScale)

                    Rectangle {
                        width: pairLbl.implicitWidth + Math.round(20 * localScale); height: Math.round(28 * localScale); radius: Math.round(8 * localScale)
                        color: pairH.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.09)
                        border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35); border.width: Math.max(1, Math.round(1 * localScale))
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { id: pairLbl; anchors.centerIn: parent; text: "Pair"; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium; color: Theme.active }
                        HoverHandler { id: pairH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: { root._removeMac = ""; root._pairingMac = ""; root._pair(dRow.device.mac, "") } }
                    }

                    Item {
                        width: Math.round(24 * localScale); height: Math.round(28 * localScale); anchors.verticalCenter: parent?.verticalCenter
                        Rectangle { anchors.fill: parent; radius: Math.round(6 * localScale); color: pinH.hovered ? Qt.rgba(1,1,1,0.10) : dRow.isPairingOpen ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12) : Qt.rgba(1,1,1,0.04); border.color: dRow.isPairingOpen ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30) : Qt.rgba(1,1,1,0.09); border.width: Math.max(1, Math.round(1 * localScale)); Behavior on color { ColorAnimation { duration: 100 } } }
                        Text { anchors.centerIn: parent; text: "󰌾"; font.pixelSize: Math.round(12 * localScale); color: dRow.isPairingOpen ? Theme.active : pinH.hovered ? Qt.rgba(1,1,1,0.7) : Qt.rgba(1,1,1,0.28); Behavior on color { ColorAnimation { duration: 100 } } }
                        HoverHandler { id: pinH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root._removeMac  = ""
                                root._pairingMac = dRow.isPairingOpen ? "" : dRow.device.mac
                                if (!dRow.isPairingOpen) Qt.callLater(function() { pinInput.forceActiveFocus() })
                                else pinInput.text = ""
                            }
                        }
                    }
                }
            }
        }

        // Expandable
        Item {
            id: expandArea
            anchors { top: baseRow.bottom; left: parent.left; right: parent.right }
            clip: true
            height: dRow.isRemovePending ? removeRow.implicitHeight + Math.round(16 * localScale) : dRow.isPairingOpen ? pinRow.implicitHeight + Math.round(16 * localScale) : 0
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            // Remove confirmation
            Item {
                id: removeRow
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Math.round(8 * localScale) }
                implicitHeight: Math.round(32 * localScale)
                opacity: dRow.isRemovePending ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }
                Rectangle {
                    anchors { fill: parent; leftMargin: Math.round(8 * localScale); rightMargin: Math.round(8 * localScale) }
                    radius: Math.round(8 * localScale); color: Qt.rgba(248/255,113/255,113/255,0.06); border.color: Qt.rgba(248/255,113/255,113/255,0.22); border.width: Math.max(1, Math.round(1 * localScale))
                    Row {
                        anchors.centerIn: parent; spacing: Math.round(12 * localScale)
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Remove this device?"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(1,1,1,0.5) }
                        Rectangle { width: Math.round(58 * localScale); height: Math.round(24 * localScale); radius: Math.round(6 * localScale); color: cxH.hovered ? Qt.rgba(1,1,1,0.09) : Qt.rgba(1,1,1,0.04); Behavior on color { ColorAnimation { duration: 80 } }
                            Text { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: Math.round(10 * localScale); color: Qt.rgba(1,1,1,0.42) }
                            HoverHandler { id: cxH; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: root._removeMac = "" }
                        }
                        Rectangle { width: Math.round(64 * localScale); height: Math.round(24 * localScale); radius: Math.round(6 * localScale); color: rxH.hovered ? Qt.rgba(248/255,113/255,113/255,0.40) : Qt.rgba(248/255,113/255,113/255,0.18); Behavior on color { ColorAnimation { duration: 80 } }
                            Text { anchors.centerIn: parent; text: "Remove"; font.pixelSize: Math.round(10 * localScale); font.weight: Font.Medium; color: "#f87171" }
                            HoverHandler { id: rxH; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: root._remove(dRow.device.mac) }
                        }
                    }
                }
            }

            // PIN row
            Item {
                id: pinRow
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Math.round(8 * localScale) }
                implicitHeight: pinCol.implicitHeight
                opacity: dRow.isPairingOpen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }
                Column {
                    id: pinCol
                    anchors { left: parent.left; right: parent.right; leftMargin: Math.round(8 * localScale); rightMargin: Math.round(8 * localScale) }
                    spacing: Math.round(6 * localScale)
                    Text { width: parent.width; text: "Legacy PIN pairing — enter the PIN shown on your device"; font.pixelSize: Math.round(10 * localScale); color: Qt.rgba(1,1,1,0.30); wrapMode: Text.WordWrap }
                    Row {
                        width: parent.width; spacing: Math.round(8 * localScale)
                        Rectangle {
                            width: parent.width - pairConfBtn.width - parent.spacing; height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                            color: Qt.rgba(1,1,1,0.06)
                            border.color: pinInput.activeFocus ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55) : Qt.rgba(1,1,1,0.12)
                            border.width: Math.max(1, Math.round(1 * localScale)); Behavior on border.color { ColorAnimation { duration: 120 } }
                            Text { anchors { left: parent.left; leftMargin: Math.round(10 * localScale); verticalCenter: parent.verticalCenter }
                            text: "PIN (optional)…"; font.pixelSize: Math.round(12 * localScale); color: Qt.rgba(1,1,1,0.22); visible: pinInput.text === "" }
                            TextInput {
                                id: pinInput
                                anchors { fill: parent; leftMargin: Math.round(10 * localScale); rightMargin: Math.round(10 * localScale) }
                                verticalAlignment: TextInput.AlignVCenter; color: Theme.text
                                font.pixelSize: Math.round(12 * localScale); font.family: "JetBrains Mono"
                                inputMethodHints: Qt.ImhDigitsOnly; maximumLength: 8
                                selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35); clip: true
                                Keys.onReturnPressed: root._pair(dRow.device.mac, text)
                            }
                        }
                        Rectangle {
                            id: pairConfBtn; width: Math.round(64 * localScale); height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                            color: pcH.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
                            border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.42); border.width: Math.max(1, Math.round(1 * localScale))
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text { anchors.centerIn: parent; text: "Pair"; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium; color: Theme.active }
                            HoverHandler { id: pcH; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: root._pair(dRow.device.mac, pinInput.text) }
                        }
                    }
                }
            }
        }

        onIsPairingOpenChanged: { if (!isPairingOpen) pinInput.text = "" }
        HoverHandler { id: rowHov; enabled: !dRow.isPaired }
    }

    // ── Main layout ───────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent; spacing: 0

        // Header
        Item {
            width: parent.width; height: Math.round(40 * localScale)

            Text { anchors { left: parent.left; leftMargin: Math.round(2 * localScale); verticalCenter: parent.verticalCenter }
            text: "Bluetooth"; font.pixelSize: Math.round(15 * localScale); font.weight: Font.Bold; color: Theme.text }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Math.round(8 * localScale)

                // Power toggle
                Rectangle {
                    width: Math.round(32 * localScale); height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                    color: pwrH.hovered ? (root._btPowered ? Qt.rgba(248/255,113/255,113/255,0.18) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)) : Qt.rgba(1,1,1,0.04)
                    border.color: root._btPowered ? Qt.rgba(1,1,1,0.10) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30); border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color        { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "⏻"; font.pixelSize: Math.round(14 * localScale); color: root._btPowered ? (pwrH.hovered ? "#f87171" : Qt.rgba(1,1,1,0.32)) : Theme.active; Behavior on color { ColorAnimation { duration: 120 } } }
                    HoverHandler { id: pwrH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root._setPower(!root._btPowered) }
                }

                // Settings — blueman-manager
                Rectangle {
                    width: Math.round(32 * localScale); height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                    color: settH.hovered ? Qt.rgba(1,1,1,0.09) : Qt.rgba(1,1,1,0.03)
                    border.color: Qt.rgba(1,1,1,0.10); border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "󰒓"; font.pixelSize: Math.round(14 * localScale); color: settH.hovered ? Qt.rgba(1,1,1,0.75) : Qt.rgba(1,1,1,0.30); Behavior on color { ColorAnimation { duration: 100 } } }
                    HoverHandler { id: settH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: { bluemanProc.running = false; bluemanProc.running = true } }
                }

                // Scan / Stop pill — disabled when adapter is off
                Rectangle {
                    width: scanRow.implicitWidth + Math.round(20 * localScale); height: Math.round(30 * localScale); radius: Math.round(15 * localScale)
                    opacity: root._btPowered ? 1.0 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    color: root._scanning ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18) : scanH.hovered && root._btPowered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12) : Qt.rgba(1,1,1,0.05)
                    border.color: root._scanning ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.48) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28); border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color { ColorAnimation { duration: 130 } }
                    Row {
                        id: scanRow; anchors.centerIn: parent; spacing: Math.round(7 * localScale)
                        Rectangle {
                            width: Math.round(7 * localScale); height: Math.round(7 * localScale); radius: Math.round(4 * localScale); anchors.verticalCenter: parent.verticalCenter
                            color: root._scanning ? Theme.active : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            SequentialAnimation on opacity { 
                                running: root._scanning; loops: Animation.Infinite; NumberAnimation { to: 0.15; duration: 450 }
                                NumberAnimation { to: 1.0; duration: 450 }
                            }
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: root._scanning ? "Stop" : "Scan"; font.pixelSize: Math.round(12 * localScale); font.weight: Font.Medium; color: root._scanning ? Theme.active : Qt.rgba(1,1,1,0.6); Behavior on color { ColorAnimation { duration: 130 } } }
                    }
                    HoverHandler { id: scanH; cursorShape: root._btPowered ? Qt.PointingHandCursor : Qt.ArrowCursor }
                    MouseArea { anchors.fill: parent; onClicked: if (root._btPowered) root._startScan() }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.07) }
        Item      { width: parent.width; height: Math.round(8 * localScale) }

        // Scan animation strip
        Item {
            width: parent.width; height: root._scanning ? Math.round(90 * localScale) : 0; clip: true
            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            ScanRings { anchors.centerIn: parent; width: Math.round(52 * localScale); height: Math.round(52 * localScale); centerGlyph: "󰂯"; glyphSize: Math.round(14 * localScale) }
            Text { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Math.round(6 * localScale) }
            text: "Scanning for devices…"; font.pixelSize: Math.round(10 * localScale); color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.50) }
        }

        Flickable {
            width: parent.width
            height: parent.height - Math.round(49 * localScale) - (root._scanning ? Math.round(90 * localScale) : 0)
            contentWidth: width; contentHeight: devCol.height
            clip: true; boundsBehavior: Flickable.StopAtBounds
            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            Column {
                id: devCol; width: parent.width; height: implicitHeight; spacing: Math.round(4 * localScale)

                Item { width: parent.width; height: visible ? pLbl.implicitHeight + Math.round(4 * localScale) : 0; visible: root._paired.length > 0
                    Text { id: pLbl; text: "PAIRED"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Bold; font.letterSpacing: 1.2; color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5) } }

                Repeater {
                    model: root._paired
                    delegate: DeviceRow { required property var modelData; width: devCol.width - Math.round(2 * localScale); x: Math.round(1 * localScale); device: modelData; isPaired: true }
                }

                Item { width: parent.width; height: Math.round(10 * localScale); visible: root._paired.length > 0 && root._available.length > 0 }

                Item { width: parent.width; height: visible ? aLbl.implicitHeight + Math.round(4 * localScale) : 0; visible: root._available.length > 0
                    Text { id: aLbl; text: root._scanning ? "DISCOVERED" : "AVAILABLE"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Bold; font.letterSpacing: 1.2; color: Qt.rgba(1,1,1,0.25) } }

                Repeater {
                    model: root._available
                    delegate: DeviceRow { required property var modelData; width: devCol.width - Math.round(2 * localScale); x: Math.round(1 * localScale); device: modelData; isPaired: false }
                }

                // Empty state
                Item {
                    width: parent.width; height: Math.round(120 * localScale)
                    visible: !root._scanning && root._allDevices.length === 0 && root._btPowered
                    Column { anchors.centerIn: parent; spacing: Math.round(10 * localScale)
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰂯"; font.pixelSize: Math.round(32 * localScale); color: Qt.rgba(1,1,1,0.08) }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No devices found"; font.pixelSize: Math.round(12 * localScale); color: Qt.rgba(1,1,1,0.2) }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Tap Scan to discover nearby devices"; font.pixelSize: Math.round(10 * localScale); color: Qt.rgba(1,1,1,0.14) }
                    }
                }

                Item { width: parent.width; height: Math.round(8 * localScale) }
            }
        }
    }

    // ── Bluetooth off overlay — anchors.fill + topMargin, no overflow ─────────
    Item {
        anchors { fill: parent; topMargin: Math.round(49 * localScale) }
        visible: !root._btPowered
        z: 2

        Rectangle { anchors.fill: parent; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.95) }

        Column {
            anchors.centerIn: parent; spacing: Math.round(16 * localScale)
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰂲"; font.pixelSize: Math.round(42 * localScale); color: Qt.rgba(1,1,1,0.12) }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Bluetooth is off"; font.pixelSize: Math.round(14 * localScale); font.weight: Font.Medium; color: Qt.rgba(1,1,1,0.30) }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: enableRow.implicitWidth + Math.round(24 * localScale); height: Math.round(34 * localScale); radius: Math.round(17 * localScale)
                color: enableH.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12)
                border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.40); border.width: Math.max(1, Math.round(1 * localScale))
                Behavior on color { ColorAnimation { duration: 120 } }
                Row { id: enableRow; anchors.centerIn: parent; spacing: Math.round(8 * localScale)
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "󰂯"; font.pixelSize: Math.round(14 * localScale); color: Theme.active }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Turn On"; font.pixelSize: Math.round(12 * localScale); font.weight: Font.Medium; color: Theme.active }
                }
                HoverHandler { id: enableH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root._setPower(true) }
            }
        }
    }
}
