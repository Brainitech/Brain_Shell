import QtQuick
import Quickshell.Io
import "../"
import "../components"

// WifiTab
// Connect → attempt without password → if "secret" in stderr → expand field inline.
// Off overlay is a direct child of root Item (z:2), not inside Column — no overflow.

Item {
    id: root

    property real localScale: 1.0
    property var    _networks:      []
    property var    _needsPassword: ({})
    property bool   _scanning:      false
    property bool   _wifiEnabled:   true
    property string _connectingTo:  ""
    property string _forgetSsid:    ""
    property string _expandSsid:    ""

    readonly property var _current: {
        for (var i = 0; i < _networks.length; i++)
            if (_networks[i].inUse) return _networks[i]
        return null
    }
    readonly property var _available: {
        var r = []
        for (var i = 0; i < _networks.length; i++)
            if (!_networks[i].inUse) r.push(_networks[i])
        return r
    }

    Connections {
        target: SurfaceState
        function onActiveContentChanged() {
            if ((SurfaceState.activeContent === "network")) {
                root._forgetSsid    = ""
                root._expandSsid    = ""
                root._connectingTo  = ""
                root._needsPassword = ({})
                root._checkRadio()
                root._scan(false)
            }
        }
    }

    // ── Processes ─────────────────────────────────────────────────────────────

    Process {
        id: scanProc
        command: []
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var t = line.trim()
                if (t === "") return
                var lastC = t.lastIndexOf(":")
                if (lastC < 0) return
                var security  = t.substring(lastC + 1)
                var t2        = t.substring(0, lastC)
                var secC      = t2.lastIndexOf(":")
                if (secC < 0) return
                var signalStr = t2.substring(secC + 1)
                var t3        = t2.substring(0, secC)
                var firstC    = t3.indexOf(":")
                if (firstC < 0) return
                var inUseStr  = t3.substring(0, firstC)
                var ssid      = t3.substring(firstC + 1).replace(/\\:/g, ":")
                if (ssid === "" || ssid === "--") return
                var inUse   = inUseStr.trim() === "*"
                var signal  = parseInt(signalStr.trim()) || 0
                var secured = security.trim() !== "" && security.trim() !== "--"
                var nets = root._networks.slice()
                var found = false
                for (var i = 0; i < nets.length; i++) {
                    if (nets[i].ssid === ssid) {
                        if (inUse || signal > nets[i].signal)
                            nets[i] = { ssid: ssid, signal: signal, secured: secured, inUse: inUse }
                        found = true; break
                    }
                }
                if (!found) nets.push({ ssid: ssid, signal: signal, secured: secured, inUse: inUse })
                root._networks = nets
            }
        }
        onRunningChanged: if (!running) root._scanning = false
    }

    // First attempt — captures stderr to detect secret requirement
    Process {
        id: connectProc
        command: []
        running: false
        property string _ssid: ""
        stderr: StdioCollector { id: connectStderr }
        onExited: function(code, status) {
            if (code === 0) {
                // Success — clear password state and close the field
                var np = Object.assign({}, root._needsPassword)
                delete np[connectProc._ssid]
                root._needsPassword = np
                root._expandSsid    = ""
            } else {
                var err = connectStderr.text.toLowerCase()
                if (err.indexOf("secret") >= 0 || err.indexOf("password") >= 0
                        || err.indexOf("no network") < 0) {
                    var np2 = Object.assign({}, root._needsPassword)
                    np2[connectProc._ssid] = true
                    root._needsPassword = np2
                    root._expandSsid    = connectProc._ssid
                }
            }
            root._connectingTo = ""
            root._scan(false)
        }
    }

    Process {
        id: passProc
        command: []
        running: false
        onRunningChanged: if (!running) {
            root._connectingTo = ""
            root._expandSsid   = ""
            root._scan(false)
        }
    }

    Process {
        id: actionProc
        command: []
        running: false
        onRunningChanged: if (!running) {
            root._connectingTo  = ""
            root._forgetSsid    = ""
            root._expandSsid    = ""
            root._needsPassword = ({})
            root._scan(false)
        }
    }

    Process { id: nmtuiProc; command: ["kitty", "--title", "nmtui", "nmtui"]; running: false }

    Process {
        id: radioProc; command: []; running: false
        onRunningChanged: if (!running) root._checkRadio()
    }

    Process {
        id: radioCheckProc
        command: ["bash", "-c", "nmcli radio wifi"]
        running: false
        stdout: SplitParser {
            onRead: function(line) { root._wifiEnabled = line.trim() === "enabled" }
        }
    }

    function _checkRadio() { radioCheckProc.running = false; radioCheckProc.running = true }

    function _setWifiEnabled(on) {
        root._wifiEnabled = on
        radioProc.command = ["bash", "-c", "nmcli radio wifi " + (on ? "on" : "off")]
        radioProc.running = false; radioProc.running = true
    }

    function _scan(rescan) {
        if (_scanning || !root._wifiEnabled) return
        _scanning = true; _networks = []
        scanProc.command = ["bash", "-c",
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list " +
            (rescan ? "--rescan yes" : "--rescan no") + " 2>/dev/null"]
        scanProc.running = false; scanProc.running = true
    }

    function _disconnect() {
        actionProc.command = ["bash", "-c",
            "nmcli con down \"$(nmcli -t -f NAME,TYPE con show --active" +
            " | grep ':802-11-wireless' | head -1 | cut -d: -f1)\" 2>/dev/null"]
        actionProc.running = false; actionProc.running = true
    }

    function _forget(ssid) {
        actionProc.running = false;
        _forgetSsid = "";
    
        actionProc.command = [
            "bash", "-c",
            "for uuid in $(nmcli -g UUID,TYPE connection show | awk -F: '$2==\"802-11-wireless\"{print $1}'); do " +
            "if [ \"$(nmcli -g 802-11-wireless.ssid connection show \"$uuid\" 2>/dev/null)\" = \"$1\" ]; then " +
            "nmcli connection delete \"$uuid\"; " +
            "fi; done",
            "--", ssid
        ];
    
        actionProc.running = true;
    }

    function _connectFirst(ssid) {
        _connectingTo = ssid; _expandSsid = ""
        connectProc._ssid = ssid
        connectProc.command = ["bash", "-c",
            "nmcli con up id \"" + ssid + "\" 2>&1 ||" +
            " nmcli dev wifi connect \"" + ssid + "\" 2>&1"]
        connectProc.running = false; connectProc.running = true
    }

    function _connectWithPassword(ssid, password) {
        _connectingTo = ssid; _expandSsid = ""
        var np = Object.assign({}, root._needsPassword)
        delete np[ssid]
        root._needsPassword = np
        passProc.command = ["bash", "-c",
            "nmcli dev wifi connect \"" + ssid + "\" password \"" + password + "\" 2>/dev/null"]
        passProc.running = false; passProc.running = true
    }

    Component.onCompleted: { _checkRadio(); _scan(false) }

    // ── Components ────────────────────────────────────────────────────────────

    component ScanRings: Item {
        id: ringsRoot
        property string centerGlyph: "󰤨"
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
                        NumberAnimation { property: "scale";   from: 0.08; to: 1.0; duration: Anim.megaSlow; easing.type: Anim.outCubic}
                        NumberAnimation { property: "opacity"; from: 0.80; to: 0.0; duration: Anim.megaSlow; easing.type: Anim.outQuad}
                    }
                }
            }
        }
        Text {
            anchors.centerIn: parent; text: ringsRoot.centerGlyph; font.pixelSize: ringsRoot.glyphSize
            color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)
            SequentialAnimation on opacity {
                running: root._scanning; loops: Animation.Infinite
                NumberAnimation { to: 0.20; duration: Anim.extraSlow; easing.type: Anim.inOutSine}
                NumberAnimation { to: 0.80; duration: Anim.extraSlow; easing.type: Anim.inOutSine}
            }
        }
    }

    component SignalBars: Item {
        id: barsRoot
        required property int signal
        width: Math.round(18 * localScale); height: Math.round(14 * localScale)
        Row {
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; spacing: Math.round(2 * localScale)
            Repeater {
                model: 4
                delegate: Rectangle {
                    required property int index
                    width: Math.round(3 * localScale); height: Math.round((4 + index * 3) * localScale); radius: Math.max(1, Math.round(1 * localScale)); anchors.bottom: parent?.bottom
                    readonly property bool lit: {
                        switch (index) {
                            case 0: return barsRoot.signal > 0
                            case 1: return barsRoot.signal > 25
                            case 2: return barsRoot.signal > 50
                            case 3: return barsRoot.signal > 75
                        }; return false
                    }
                    color: lit ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.85) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.15)
                    Behavior on color { ColorAnimation { duration: Anim.normal} }
                }
            }
        }
    }

    component NetworkRow: Item {
        id: netRow
        required property var  net
        required property bool isCurrent
        readonly property bool isForgetPending: root._forgetSsid   === net.ssid
        readonly property bool isExpanded:      root._expandSsid   === net.ssid
        readonly property bool isConnecting:    root._connectingTo === net.ssid
        readonly property bool needsPassword:   !!root._needsPassword[net.ssid]
        property bool _showPass: false
        width: parent?.width ?? 0
        height: baseRow.height + expandArea.height

        Rectangle {
            anchors.fill: parent; radius: Math.round(Theme.cornerRadius * localScale)
            color: netRow.isCurrent
                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
                : rHov.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.04) : "transparent"
            border.color: netRow.isCurrent
                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                : netRow.needsPassword
                    ? Qt.rgba(245/255,196/255,122/255,0.30)
                    : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.06)
            border.width: Math.max(1, Math.round(1 * localScale))
            Behavior on color        { ColorAnimation { duration: Anim.color} }
            Behavior on border.color { ColorAnimation { duration: Anim.color} }
        }

        Item {
            id: baseRow
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: Math.round(48 * localScale)

            Column {
                anchors { left: parent.left; leftMargin: Math.round(12 * localScale); verticalCenter: parent.verticalCenter }
                spacing: Math.round(3 * localScale)
                Text {
                    text: netRow.net.ssid; font.pixelSize: Math.round(13 * localScale)
                    font.weight: netRow.isCurrent ? Font.Medium : Font.Normal
                    color: netRow.isCurrent ? Theme.text : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.7)
                    width: Math.round(170 * localScale); elide: Text.ElideRight
                }
                Text {
                    visible: netRow.needsPassword && !netRow.isCurrent
                    text: "Password required"; font.pixelSize: Math.round(10 * localScale)
                    color: Qt.rgba(245/255,196/255,122/255,0.80)
                }
                Text { visible: netRow.isCurrent; text: "Connected"; font.pixelSize: Math.round(10 * localScale); color: Theme.active }
            }

            Row {
                anchors { right: parent.right; rightMargin: Math.round(10 * localScale); verticalCenter: parent.verticalCenter }
                spacing: Math.round(6 * localScale)

                Text {
                    visible: netRow.net.secured && !netRow.isCurrent
                    text: "󰌾"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.28)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item {
                    width: Math.round(22 * localScale); height: Math.round(16 * localScale); anchors.verticalCenter: parent.verticalCenter
                    SignalBars { anchors.centerIn: parent; signal: netRow.net.signal }
                }
                Item {
                    visible: netRow.isConnecting; width: Math.round(20 * localScale); height: Math.round(20 * localScale); anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent; text: "○"; font.pixelSize: Math.round(14 * localScale); color: Theme.active
                        SequentialAnimation on opacity {
                            running: netRow.isConnecting; loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: Anim.verySlow}
                            NumberAnimation { to: 1.0; duration: Anim.verySlow}
                        }
                    }
                }
                // Disconnect
                Item {
                    visible: netRow.isCurrent; width: Math.round(28 * localScale); height: Math.round(28 * localScale); anchors.verticalCenter: parent.verticalCenter
                    Rectangle { anchors.fill: parent; radius: Math.round(6 * localScale); color: dH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.10) : "transparent"; Behavior on color { ColorAnimation { duration: Anim.fast} } }
                    Text { anchors.centerIn: parent; text: "󰖪"; font.pixelSize: Math.round(14 * localScale); color: dH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.65) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.35); Behavior on color { ColorAnimation { duration: Anim.fast} } }
                    HoverHandler { id: dH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root._disconnect() }
                }
                // Forget
                Item {
                    visible: netRow.isCurrent; width: Math.round(28 * localScale); height: Math.round(28 * localScale); anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        anchors.fill: parent; radius: Math.round(6 * localScale)
                        color: fH.hovered ? Qt.rgba(248/255,113/255,113/255,0.15) : netRow.isForgetPending ? Qt.rgba(248/255,113/255,113/255,0.10) : "transparent"
                        Behavior on color { ColorAnimation { duration: Anim.fast} }
                    }
                    Text { anchors.centerIn: parent; text: "󰗼"; font.pixelSize: Math.round(13 * localScale); color: (fH.hovered || netRow.isForgetPending) ? "#f87171" : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.3); Behavior on color { ColorAnimation { duration: Anim.fast} } }
                    HoverHandler { id: fH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root._forgetSsid = netRow.isForgetPending ? "" : netRow.net.ssid }
                }
                // Connect
                Rectangle {
                    visible: !netRow.isCurrent && !netRow.isConnecting
                    anchors.verticalCenter: parent.verticalCenter
                    width: connectLbl.implicitWidth + Math.round(20 * localScale); height: Math.round(28 * localScale); radius: Math.round(8 * localScale)
                    color: conH.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.09)
                    border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35); border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color { ColorAnimation { duration: Anim.fast} }
                    Text { id: connectLbl; anchors.centerIn: parent; text: netRow.isExpanded ? "Retry" : "Connect"; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium; color: Theme.active }
                    HoverHandler { id: conH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root._forgetSsid = ""
                            if (netRow.isExpanded && passInput.text !== "")
                                root._connectWithPassword(netRow.net.ssid, passInput.text)
                            else
                                root._connectFirst(netRow.net.ssid)
                        }
                    }
                }
            }
        }

        Item {
            id: expandArea
            anchors { top: baseRow.bottom; left: parent.left; right: parent.right }
            clip: true
            height: netRow.isForgetPending ? forgetRow.implicitHeight + Math.round(16 * localScale) : netRow.isExpanded ? passRow.implicitHeight + Math.round(16 * localScale) : 0
            Behavior on height { NumberAnimation { duration: Anim.normal; easing.type: Anim.outCubic} }

            Item {
                id: forgetRow
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Math.round(8 * localScale) }
                implicitHeight: Math.round(32 * localScale)
                opacity: netRow.isForgetPending ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Anim.mediumFast} }
                Rectangle {
                    anchors { fill: parent; leftMargin: Math.round(10 * localScale); rightMargin: Math.round(10 * localScale) }
                    radius: Math.round(8 * localScale); color: Qt.rgba(248/255,113/255,113/255,0.07)
                    border.color: Qt.rgba(248/255,113/255,113/255,0.22); border.width: Math.max(1, Math.round(1 * localScale))
                    Row {
                        anchors.centerIn: parent; spacing: Math.round(12 * localScale)
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Forget this network?"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.55) }
                        Rectangle {
                            width: Math.round(54 * localScale); height: Math.round(24 * localScale); radius: Math.round(6 * localScale); color: cfH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.09) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.04)
                            Behavior on color { ColorAnimation { duration: Anim.superFast} }
                            Text { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: Math.round(10 * localScale); color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.45) }
                            HoverHandler { id: cfH; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: root._forgetSsid = "" }
                        }
                        Rectangle {
                            width: Math.round(54 * localScale); height: Math.round(24 * localScale); radius: Math.round(6 * localScale)
                            color: ffH.hovered ? Qt.rgba(248/255,113/255,113/255,0.35) : Qt.rgba(248/255,113/255,113/255,0.18)
                            Behavior on color { ColorAnimation { duration: Anim.superFast} }
                            Text { anchors.centerIn: parent; text: "Forget"; font.pixelSize: Math.round(10 * localScale); font.weight: Font.Medium; color: "#f87171" }
                            HoverHandler { id: ffH; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: root._forget(netRow.net.ssid) }
                        }
                    }
                }
            }

            Item {
                id: passRow
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Math.round(8 * localScale) }
                implicitHeight: Math.round(40 * localScale)
                opacity: netRow.isExpanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Anim.mediumFast} }
                Row {
                    anchors { fill: parent; leftMargin: Math.round(10 * localScale); rightMargin: Math.round(10 * localScale) }
                    spacing: Math.round(8 * localScale)
                    Rectangle {
                        width: parent.width - parent.spacing; height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                        color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.06)
                        border.color: passInput.activeFocus ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.12)
                        border.width: Math.max(1, Math.round(1 * localScale)); Behavior on border.color { ColorAnimation { duration: Anim.color} }
                        Text { anchors { left: parent.left; leftMargin: Math.round(10 * localScale); verticalCenter: parent.verticalCenter }
                        text: "Password…"; font.pixelSize: Math.round(12 * localScale); color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.22); visible: passInput.text === "" }
                        TextInput {
                            id: passInput
                            // Updated anchors to make room for the eye button
                            anchors { left: parent.left; leftMargin: Math.round(10 * localScale); right: eyeBtn.left; rightMargin: Math.round(6 * localScale); top: parent.top; bottom: parent.bottom }
                            verticalAlignment: TextInput.AlignVCenter; color: Theme.text; font.pixelSize: Math.round(12 * localScale)
                            // Toggle echoMode based on state
                            echoMode: netRow._showPass ? TextInput.Normal : TextInput.Password
                            selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35); clip: true
                            Keys.onReturnPressed: { if (text.length > 0) root._connectWithPassword(netRow.net.ssid, text) }
                        }

                        // Added Show Password Button
                        Item {
                            id: eyeBtn
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: Math.round(28 * localScale); height: Math.round(28 * localScale)
                            Rectangle { anchors.fill: parent; radius: Math.round(6 * localScale); color: eyeH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.08) : "transparent" }
                            Text { 
                                anchors.centerIn: parent
                                text: netRow._showPass ? "" : ""
                                font.pixelSize: Math.round(13 * localScale)
                                color: netRow._showPass ? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.28) 
                            }
                            HoverHandler { id: eyeH; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: netRow._showPass = !netRow._showPass }
                        }
                    }
                }
            }

            onVisibleChanged: { if (visible && netRow.isExpanded) Qt.callLater(function() { passInput.forceActiveFocus() }) }
        }

        onIsExpandedChanged: {
            if (isExpanded) Qt.callLater(function() { passInput.forceActiveFocus() })
            else            passInput.text = ""
        }

        HoverHandler { id: rHov; enabled: !netRow.isCurrent }
    }

    // ── Layout — Column fills root, overlay is z:2 sibling ───────────────────
    Column {
        anchors.fill: parent; spacing: 0

        Item {
            width: parent.width; height: Math.round(40 * localScale)
            Text { anchors { left: parent.left; leftMargin: Math.round(2 * localScale); verticalCenter: parent.verticalCenter }
            text: "Wi-Fi"; font.pixelSize: Math.round(15 * localScale); font.weight: Font.Bold; color: Theme.text }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Math.round(8 * localScale)

                Rectangle {
                    width: Math.round(32 * localScale); height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                    color: wfPwrH.hovered ? (root._wifiEnabled ? Qt.rgba(248/255,113/255,113/255,0.18) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.04)
                    border.color: root._wifiEnabled ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.10) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30)
                    border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color        { ColorAnimation { duration: Anim.color} }
                    Behavior on border.color { ColorAnimation { duration: Anim.color} }
                    Text { anchors.centerIn: parent; text: "⏻"; font.pixelSize: Math.round(14 * localScale); color: root._wifiEnabled ? (wfPwrH.hovered ? "#f87171" : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.32)) : Theme.active; Behavior on color { ColorAnimation { duration: Anim.color} } }
                    HoverHandler { id: wfPwrH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root._setWifiEnabled(!root._wifiEnabled) }
                }

                Rectangle {
                    width: Math.round(32 * localScale); height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                    color: settH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.09) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.03)
                    border.color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.10); border.width: Math.max(1, Math.round(1 * localScale)); Behavior on color { ColorAnimation { duration: Anim.fast} }
                    Text { anchors.centerIn: parent; text: "󰒓"; font.pixelSize: Math.round(14 * localScale); color: settH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.75) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.30); Behavior on color { ColorAnimation { duration: Anim.fast} } }
                    HoverHandler { id: settH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: { nmtuiProc.running = false; nmtuiProc.running = true } }
                }

                Rectangle {
                    width: Math.round(32 * localScale); height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                    color: rfH.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.05)
                    border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28); border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color { ColorAnimation { duration: Anim.color} }
                    Text {
                        id: rfIcon; anchors.centerIn: parent; text: "󰑐"; font.pixelSize: Math.round(15 * localScale)
                        color: root._scanning ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4) : (root._wifiEnabled ? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.18))
                        Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
                        RotationAnimator { target: rfIcon; from: 0; to: 360; duration: Anim.megaSlow; loops: Animation.Infinite; running: root._scanning; easing.type: Anim.linear}
                    }
                    HoverHandler { id: rfH; cursorShape: root._wifiEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
                    MouseArea { anchors.fill: parent; onClicked: if (!root._scanning && root._wifiEnabled) root._scan(true) }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.07) }
        Item      { width: parent.width; height: Math.round(8 * localScale) }

        Flickable {
            id: flick; width: parent.width; height: parent.height - Math.round(49 * localScale)
            contentWidth: width; contentHeight: contentCol.height; clip: true; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: contentCol; width: flick.width; height: implicitHeight; spacing: Math.round(4 * localScale)

                Item { width: parent.width; height: visible ? sLbl1.implicitHeight + Math.round(4 * localScale) : 0; visible: root._current !== null
                    Text { id: sLbl1; text: "CONNECTED"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Bold; font.letterSpacing: 1.2; color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5) } }

                NetworkRow { visible: root._current !== null; width: parent.width - Math.round(2 * localScale); x: Math.round(1 * localScale); net: root._current ?? { ssid: "", signal: 0, secured: false, inUse: true }; isCurrent: true }

                Item { width: parent.width; height: Math.round(10 * localScale); visible: root._current !== null && root._available.length > 0 }

                Item { width: parent.width; height: visible ? sLbl2.implicitHeight + Math.round(4 * localScale) : 0; visible: root._available.length > 0
                    Text { id: sLbl2; text: "AVAILABLE"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Bold; font.letterSpacing: 1.2; color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.25) } }

                Repeater {
                    model: root._available
                    delegate: NetworkRow { required property var modelData; width: contentCol.width - Math.round(2 * localScale); x: Math.round(1 * localScale); net: modelData; isCurrent: false }
                }

                // Empty state
                Item {
                    width: parent.width; height: Math.round(160 * localScale)
                    visible: !root._scanning && root._networks.length === 0 && root._wifiEnabled
                    Column { anchors.centerIn: parent; spacing: Math.round(10 * localScale)
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰤭"; font.pixelSize: Math.round(34 * localScale); color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.08) }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No networks found"; font.pixelSize: Math.round(12 * localScale); color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.2) } }
                }

                Item {
                    width: parent.width; height: Math.round(160 * localScale)
                    visible: root._scanning && root._networks.length === 0
                    ScanRings { anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Math.round(12 * localScale) }
                    width: Math.round(96 * localScale); height: Math.round(96 * localScale); centerGlyph: "󰤨"; glyphSize: Math.round(18 * localScale) }
                    Text { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Math.round(8 * localScale) }
                    text: "Scanning…"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5) }
                }

                Item { width: parent.width; height: Math.round(8 * localScale) }
            }
        }
    }

    // ── WiFi off overlay — covers list area only, stops at parent bounds ─────
    Item {
        anchors {
            fill:      parent
            topMargin: Math.round(49 * localScale)   // below header 40 + divider 1 + gap 8
        }
        visible: !root._wifiEnabled
        z: 2

        Rectangle { anchors.fill: parent; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.95) }

        Column {
            anchors.centerIn: parent; spacing: Math.round(16 * localScale)
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰤭"; font.pixelSize: Math.round(42 * localScale); color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.12) }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Wi-Fi is off"; font.pixelSize: Math.round(14 * localScale); font.weight: Font.Medium; color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.30) }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: wfEnRow.implicitWidth + Math.round(24 * localScale); height: Math.round(34 * localScale); radius: Math.round(17 * localScale)
                color: wfEnH.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12)
                border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.40); border.width: Math.max(1, Math.round(1 * localScale))
                Behavior on color { ColorAnimation { duration: Anim.color} }
                Row { id: wfEnRow; anchors.centerIn: parent; spacing: Math.round(8 * localScale)
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "󰤨"; font.pixelSize: Math.round(14 * localScale); color: Theme.active }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Turn On"; font.pixelSize: Math.round(12 * localScale); font.weight: Font.Medium; color: Theme.active }
                }
                HoverHandler { id: wfEnH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root._setWifiEnabled(true) }
            }
        }
    }
}
