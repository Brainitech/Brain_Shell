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
import Quickshell.Io
import "../"
import "../components"
import "../services"
import "network"

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
            if (SurfaceState.activeContent === "network") {
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
        actionProc.running = false
        _forgetSsid = ""
        actionProc.command = [
            "bash", "-c",
            "for uuid in $(nmcli -g UUID,TYPE connection show | awk -F: '$2==\"802-11-wireless\"{print $1}'); do " +
            "if [ \"$(nmcli -g 802-11-wireless.ssid connection show \"$uuid\" 2>/dev/null)\" = \"$1\" ]; then " +
            "nmcli connection delete \"$uuid\"; " +
            "fi; done",
            "--", ssid
        ]
        actionProc.running = true
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

    // ── Layout ────────────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent; spacing: 0

        // Header
        Item {
            width: parent.width; height: Math.round(40 * localScale)
            Text {
                anchors { left: parent.left; leftMargin: Math.round(2 * localScale); verticalCenter: parent.verticalCenter }
                text: "Wi-Fi"; font.pixelSize: Math.round(15 * localScale); font.weight: Font.Bold; color: Theme.text
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Math.round(8 * localScale)

                // Power toggle
                Rectangle {
                    width: Math.round(32 * localScale); height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                    color: wfPwrH.hovered
                        ? (root._wifiEnabled ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18))
                        : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                    border.color: root._wifiEnabled ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30)
                    border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color        { ColorAnimation { duration: Anim.color } }
                    Behavior on border.color { ColorAnimation { duration: Anim.color } }
                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        font.pixelSize: Math.round(14 * localScale)
                        color: root._wifiEnabled ? (wfPwrH.hovered ? Theme.error : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.32)) : Theme.active
                        Behavior on color { ColorAnimation { duration: Anim.color } }
                    }
                    HoverHandler { id: wfPwrH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root._setWifiEnabled(!root._wifiEnabled) }
                }

                // Settings (nmtui)
                Rectangle {
                    width: Math.round(32 * localScale); height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                    color: settH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.09) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.03)
                    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
                    border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        font.pixelSize: Math.round(14 * localScale)
                        color: settH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.75) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.30)
                        Behavior on color { ColorAnimation { duration: Anim.fast } }
                    }
                    HoverHandler { id: settH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: { nmtuiProc.running = false; nmtuiProc.running = true } }
                }

                // Refresh scan
                Rectangle {
                    width: Math.round(32 * localScale); height: Math.round(32 * localScale); radius: Math.round(8 * localScale)
                    color: rfH.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28)
                    border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color { ColorAnimation { duration: Anim.color } }
                    Text {
                        id: rfIcon
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.pixelSize: Math.round(15 * localScale)
                        color: root._scanning ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.4) : (root._wifiEnabled ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18))
                        Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
                        RotationAnimator { target: rfIcon; from: 0; to: 360; duration: Anim.megaSlow; loops: Animation.Infinite; running: root._scanning; easing.type: Anim.linear }
                    }
                    HoverHandler { id: rfH; cursorShape: root._wifiEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
                    MouseArea { anchors.fill: parent; onClicked: if (!root._scanning && root._wifiEnabled) root._scan(true) }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07) }
        Item      { width: parent.width; height: Math.round(8 * localScale) }

        Flickable {
            id: flick
            width: parent.width
            height: parent.height - Math.round(49 * localScale)
            contentWidth: width
            contentHeight: contentCol.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: contentCol
                width: flick.width
                height: implicitHeight
                spacing: Math.round(4 * localScale)

                // ── ETHERNET (Always on top, independent of Wi-Fi state) ─────────
                Item {
                    id: ethSection
                    width: parent.width
                    height: visible ? ethCol.implicitHeight + Math.round(12 * localScale) : 0
                    visible: NetworkService.ethernet

                    Column {
                        id: ethCol
                        width: parent.width - Math.round(2 * localScale)
                        x: Math.round(1 * localScale)
                        spacing: Math.round(4 * localScale)

                        Text {
                            text: "ETHERNET"
                            font.pixelSize: Math.round(9 * localScale)
                            font.weight: Font.Bold
                            font.letterSpacing: 1.2
                            color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5)
                        }

                        Rectangle {
                            width: parent.width
                            height: Math.round(48 * localScale)
                            radius: Math.round(Theme.cornerRadius * localScale)
                            color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
                            border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                            border.width: Math.max(1, Math.round(1 * localScale))

                            Row {
                                anchors {
                                    left: parent.left; leftMargin: Math.round(12 * localScale)
                                    right: parent.right; rightMargin: Math.round(10 * localScale)
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: Math.round(10 * localScale)

                                Text {
                                    text: ""
                                    font.pixelSize: Math.round(18 * localScale)
                                    color: Theme.active
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Math.round(3 * localScale)

                                    Text {
                                        text: NetworkService.ethernetName !== "" ? NetworkService.ethernetName : "Wired Connection"
                                        font.pixelSize: Math.round(13 * localScale)
                                        font.weight: Font.Medium
                                        color: Theme.text
                                        width: Math.round(170 * localScale)
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: NetworkService.connectivity === "portal"
                                            ? "Action Needed"
                                            : (NetworkService.connectivity === "none" || NetworkService.connectivity === "limited")
                                                ? "No Internet"
                                                : "Connected"
                                        font.pixelSize: Math.round(10 * localScale)
                                        color: NetworkService.connectivity === "full" ? Theme.active : Qt.rgba(245/255, 196/255, 122/255, 1.0)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── CURRENT CONNECTED WI-FI ───────────────────────────────────
                Item {
                    width: parent.width
                    height: visible ? sLbl1.implicitHeight + Math.round(4 * localScale) : 0
                    visible: root._wifiEnabled && root._current !== null
                    Text {
                        id: sLbl1
                        text: "WI-FI"
                        font.pixelSize: Math.round(9 * localScale)
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                        color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5)
                    }
                }

                WifiNetworkRow {
                    visible: root._wifiEnabled && root._current !== null
                    width: contentCol.width - Math.round(2 * localScale)
                    x: Math.round(1 * localScale)
                    net: root._current ?? { ssid: "", signal: 0, secured: false, inUse: true }
                    isCurrent: true
                    localScale: root.localScale
                    isForgetPending: root._forgetSsid === (root._current ? root._current.ssid : "")
                    isExpanded: root._expandSsid === (root._current ? root._current.ssid : "")
                    isConnecting: root._connectingTo === (root._current ? root._current.ssid : "")
                    needsPassword: !!(root._current && root._needsPassword[root._current.ssid])

                    onConnectClicked: function(ssid, password) {
                        root._forgetSsid = ""
                        if (password !== "") root._connectWithPassword(ssid, password)
                        else root._connectFirst(ssid)
                    }
                    onDisconnectClicked: root._disconnect()
                    onToggleForget: function(ssid) {
                        root._forgetSsid = (root._forgetSsid === ssid) ? "" : ssid
                    }
                    onCancelForget: root._forgetSsid = ""
                    onConfirmForget: function(ssid) { root._forget(ssid) }
                    onCancelExpand: root._expandSsid = ""
                }

                Item {
                    width: parent.width
                    height: Math.round(10 * localScale)
                    visible: root._wifiEnabled && root._current !== null && root._available.length > 0
                }

                // ── AVAILABLE NETWORKS ────────────────────────────────────────
                Item {
                    width: parent.width
                    height: visible ? sLbl2.implicitHeight + Math.round(4 * localScale) : 0
                    visible: root._wifiEnabled && root._available.length > 0
                    Text {
                        id: sLbl2
                        text: "AVAILABLE"
                        font.pixelSize: Math.round(9 * localScale)
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                    }
                }

                Repeater {
                    model: root._wifiEnabled ? root._available : []
                    delegate: WifiNetworkRow {
                        required property var modelData
                        width: contentCol.width - Math.round(2 * localScale)
                        x: Math.round(1 * localScale)
                        net: modelData
                        isCurrent: false
                        localScale: root.localScale
                        isForgetPending: root._forgetSsid === modelData.ssid
                        isExpanded: root._expandSsid === modelData.ssid
                        isConnecting: root._connectingTo === modelData.ssid
                        needsPassword: !!root._needsPassword[modelData.ssid]

                        onConnectClicked: function(ssid, password) {
                            root._forgetSsid = ""
                            if (password !== "") root._connectWithPassword(ssid, password)
                            else root._connectFirst(ssid)
                        }
                        onDisconnectClicked: root._disconnect()
                        onToggleForget: function(ssid) {
                            root._forgetSsid = (root._forgetSsid === ssid) ? "" : ssid
                        }
                        onCancelForget: root._forgetSsid = ""
                        onConfirmForget: function(ssid) { root._forget(ssid) }
                        onCancelExpand: root._expandSsid = ""
                    }
                }

                // Empty state
                Item {
                    width: parent.width
                    height: Math.round(160 * localScale)
                    visible: root._wifiEnabled && !root._scanning && root._networks.length === 0
                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(10 * localScale)
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰤭"; font.pixelSize: Math.round(34 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No networks found"; font.pixelSize: Math.round(12 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2) }
                    }
                }

                // Scanning indicator
                Item {
                    width: parent.width
                    height: Math.round(160 * localScale)
                    visible: root._wifiEnabled && root._scanning && root._networks.length === 0
                    ScanRings {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Math.round(12 * localScale) }
                        width: Math.round(96 * localScale)
                        height: Math.round(96 * localScale)
                        centerGlyph: "󰤨"
                        glyphSize: Math.round(18 * localScale)
                        running: root._scanning
                        localScale: root.localScale
                    }
                    Text {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Math.round(8 * localScale) }
                        text: "Scanning…"; font.pixelSize: Math.round(11 * localScale); color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5)
                    }
                }

                // ── WI-FI OFF STATE (Displayed beneath Ethernet if Ethernet is on) ──
                Item {
                    id: wifiOffView
                    width: parent.width
                    height: Math.max(Math.round(220 * localScale), flick.height - (ethSection.visible ? ethSection.height + Math.round(16 * localScale) : 0))
                    visible: !root._wifiEnabled

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(16 * localScale)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰤭"
                            font.pixelSize: Math.round(42 * localScale)
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Wi-Fi is off"
                            font.pixelSize: Math.round(14 * localScale)
                            font.weight: Font.Medium
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.30)
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: wfEnRow.implicitWidth + Math.round(24 * localScale)
                            height: Math.round(34 * localScale)
                            radius: Math.round(17 * localScale)
                            color: wfEnH.hovered
                                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22)
                                : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12)
                            border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.40)
                            border.width: Math.max(1, Math.round(1 * localScale))
                            Behavior on color { ColorAnimation { duration: Anim.color } }

                            Row {
                                id: wfEnRow
                                anchors.centerIn: parent
                                spacing: Math.round(8 * localScale)

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰤨"
                                    font.pixelSize: Math.round(14 * localScale)
                                    color: Theme.active
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Turn On"
                                    font.pixelSize: Math.round(12 * localScale)
                                    font.weight: Font.Medium
                                    color: Theme.active
                                }
                            }

                            HoverHandler { id: wfEnH; cursorShape: Qt.PointingHandCursor }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root._setWifiEnabled(true)
                            }
                        }
                    }
                }

                Item { width: parent.width; height: Math.round(8 * localScale) }
            }
        }
    }
}
