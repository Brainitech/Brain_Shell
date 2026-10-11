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
import QtQuick.Controls
import "../"
import "../../"
import "../../components"

Item {
    id: root
    property real localScale: 1.0
    property bool showHyprlandKeybinds: false

    onShowHyprlandKeybindsChanged: {
        if (showHyprlandKeybinds) KeybindService.loadHyprBinds()
    }

    // ── Capture state ─────────────────────────────────────────────────────────
    property string _capturing: ""
    readonly property bool anyCapturing: _capturing !== ""

    // Keep KeybindService in sync so external handlers can observe it.
    // In ShellState / Popups, watch KeybindService.isCapturing and dispatch:
    //   true  →  hyprctl dispatch submap, clean
    //   false →  hyprctl dispatch submap, reset
    onAnyCapturingChanged: KeybindService.isCapturing = anyCapturing

    // ── Pending changes ───────────────────────────────────────────────────────
    property var  _pending:   ({})
    readonly property bool hasPending: Object.keys(_pending).length > 0

    function _addPending(action, mods, key) {
        if (!key || key === "" || key.toUpperCase() === "UNKNOWN") return
        var copy = Object.assign({}, _pending)
        copy[action] = { mods: mods, key: key }
        _pending = copy
    }

    function _clearPending(action) {
        var copy = Object.assign({}, _pending)
        delete copy[action]
        _pending = copy
    }

	function _applyPending() {
        var ks = Object.keys(_pending)
        for (var i = 0; i < ks.length; i++) {
            var m = _pending[ks[i]].mods
            var k = _pending[ks[i]].key
            if (!k || k === "" || k.toUpperCase() === "UNKNOWN") continue
            if (m === "" && k === "") {
                KeybindService.unbindBinding(ks[i])
            } else {
                KeybindService.updateBinding(ks[i], m, k)
            }
        }
        _pending = {}
        KeybindService.saveAndReload()
    }

    // ── Groups ────────────────────────────────────────────────────────────────
    readonly property var _groups: {
        var groups = {}; var order = []
        var defs = KeybindService._defaults
        var ks   = Object.keys(defs)
        for (var i = 0; i < ks.length; i++) {
            var g = defs[ks[i]].group
            if (!groups[g]) { groups[g] = []; order.push(g) }
            groups[g].push(ks[i])
        }
        return order.map(function(g) { return { name: g, actions: groups[g] } })
    }

    // ── Save banner ───────────────────────────────────────────────────────────
    Rectangle {
        id: _saveBanner
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: root.hasPending ? Math.round(44 * localScale) : 0
        clip:   true
        color:  Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
        border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.20)
        border.width: root.hasPending ? 1 : 0
        radius: Math.round(8 * localScale)

        Behavior on height { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod} }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Math.round(10 * localScale) }
            spacing: Math.round(8 * localScale)
            visible: root.hasPending

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var n = Object.keys(root._pending).length
                    return n + " unsaved change" + (n > 1 ? "s" : "")
                }
                font.pixelSize: Math.round(11 * localScale)
                color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.70)
            }

            // Discard
            Rectangle {
                width: Math.round(62 * localScale); height: Math.round(26 * localScale); radius: Math.round(7 * localScale)
                color: _discardH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.13); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.fast} }
                Text { anchors.centerIn: parent; text: "Discard"; font.pixelSize: Math.round(10 * localScale)
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.48) }
                HoverHandler { id: _discardH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root._pending = {} }
            }

            // Save
            Rectangle {
                width: Math.round(62 * localScale); height: Math.round(26 * localScale); radius: Math.round(7 * localScale)
                color: _saveH.hovered
                    ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28)
                    : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.16)
                border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.42)
                border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.fast} }
                Text { anchors.centerIn: parent; text: "Save"; font.pixelSize: Math.round(10 * localScale)
                    font.weight: Font.Medium; color: Theme.active }
                HoverHandler { id: _saveH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root._applyPending() }
            }
        }
    }

    Text {
        id: _titleLabel
        anchors {
            top: _saveBanner.bottom
            topMargin: Math.round(16 * localScale)
            left: parent.left
            leftMargin: Math.round(12 * localScale)
        }
        text: root.showHyprlandKeybinds ? "Hyprland Keybinds (Read-Only)" : "Brain Shell Keybinds"
        font.pixelSize: Math.round(16 * localScale)
        font.weight: Font.Bold
        color: Theme.text
    }

    function resetScroll() { flick.contentY = 0; flick.returnToBounds() }

    // ── Scrollable list ───────────────────────────────────────────────────────
    Flickable {
        id: flick
        anchors {
            top:         _titleLabel.bottom
            left:        parent.left
            right:       parent.right
            bottom:      parent.bottom
            leftMargin:  Math.round(12 * localScale)
            rightMargin: Math.round(12 * localScale)
            bottomMargin: Math.round(12 * localScale)
            topMargin:   Math.round(12 * localScale)
        }
        contentWidth:   width
        contentHeight:  (root.showHyprlandKeybinds ? _hyprCol.implicitHeight : _col.implicitHeight) + Math.round(16 * localScale)
        clip:           true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: Math.round(3 * localScale); implicitHeight: Math.round(40 * localScale); radius: 1.5 * localScale
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.22)
            }
            background: Item {}
        }

        Column {
            id: _col
            visible: !root.showHyprlandKeybinds
            width:   parent.width - Math.round(12 * localScale)
            spacing: Math.round(32 * localScale)

            Repeater {
                model: root._groups
                delegate: SettingsGroup {
                    required property var modelData
                    required property int index
                    width:   _col.width
                    title:   modelData.name
                    localScale: root.localScale

                    Repeater {
                        model: modelData.actions
                        delegate: Column {
                            width: parent.width
                            
                            SettingsDivider {
                                localScale: root.localScale
                                visible: index > 0
                                width: parent.width
                            }
                            KeybindRowDelegate {
                                id: _br
                                width:        parent.width
                                localScale:   root.localScale
                                action:       modelData
                                isCapturing:  root._capturing === modelData
                                pendingCombo: root._pending[modelData] || null
                                pendingMap:   root._pending
                                anyCapturing: root.anyCapturing
                                onRequestCapture: root._capturing = modelData
                                onReleaseCapture: root._capturing = ""
                                onCaptureAccepted: function(newMods, newKey) {
                                    root._addPending(_br.action, newMods, newKey)
                                }
                                onClearRequested: function(act) {
                                    root._addPending(act, "", "")
                                }
                                onResetRequested: function(act) {
                                    if (_br._isPending) {
                                        var def = KeybindService._defaults[act]
                                        if (_br._b && _br._b.mods === def.mods && _br._b.key === def.key)
                                            root._clearPending(act)
                                        else
                                            root._addPending(act, def.mods, def.key)
                                    } else {
                                        KeybindService.resetBinding(act)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Column {
            id: _hyprCol
            visible: root.showHyprlandKeybinds
            width:   parent.width - Math.round(12 * localScale)
            spacing: Math.round(32 * localScale)
            
            Repeater {
                model: root._getHyprGroups()
                delegate: SettingsGroup {
                    required property var modelData
                    required property int index
                    width: _hyprCol.width
                    title: modelData.name
                    localScale: root.localScale
                    
                    Repeater {
                        model: modelData.actions
                        delegate: Column {
                            width: parent.width
                            
                            SettingsDivider {
                                localScale: root.localScale
                                visible: index > 0
                                width: parent.width
                            }
                            
                            Item {
                                width: parent.width; height: Math.round(48 * localScale)
                                Text {
                                    anchors { left: parent.left; leftMargin: Math.round(16 * localScale); verticalCenter: parent.verticalCenter; right: _pillRect.left; rightMargin: Math.round(16 * localScale) }
                                    text: modelData.desc
                                    font.pixelSize: Math.round(13 * localScale)
                                    color: Theme.text
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    id: _pillRect
                                    anchors { right: parent.right; rightMargin: Math.round(16 * localScale); verticalCenter: parent.verticalCenter }
                                    width: _hyprTxt.implicitWidth + Math.round(20 * localScale)
                                    height: Math.round(26 * localScale)
                                    radius: Math.round(4 * localScale)
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                                    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                                    border.width: 1
                                    
                                    Text {
                                        id: _hyprTxt
                                        anchors.centerIn: parent
                                        text: modelData.bind
                                        font.pixelSize: Math.round(11 * localScale)
                                        font.family: "monospace"
                                        color: Theme.subtext
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function _maskToMods(mask) {
        var p = []
        if (mask & 64) p.push("SUPER")
        if (mask & 4)  p.push("CTRL")
        if (mask & 8)  p.push("ALT")
        if (mask & 1)  p.push("SHIFT")
        return p.join(" + ")
    }

    function _getHyprGroups() {
        var groups = {
            "Launch Applications": [],
            "Close / Exit": [],
            "Workspace Management": [],
            "Window Management": [],
            "Other": []
        }
        var binds = KeybindService._hyprBinds || []
        for (var i = 0; i < binds.length; i++) {
            var b = binds[i]
            if (b.submap !== "" && b.submap_universal !== "true") continue
            
            var d = (b.dispatcher || "Unknown").toLowerCase()
            
            // Ignore Brain Shell native binds
            if (d === "exec" && b.arg && (b.arg.indexOf("qs ipc") !== -1 || b.arg.indexOf("quickshell ipc") !== -1 || b.arg.indexOf("brain-shell ipc") !== -1)) continue
            
            var groupName = "Other"
            if (d === "exec") {
                groupName = "Launch Applications"
            } else if (d === "killactive" || d === "exit" || d === "forcekillactive") {
                groupName = "Close / Exit"
            } else if (d.indexOf("workspace") !== -1) {
                groupName = "Workspace Management"
            } else if (d === "movewindow" || d === "resizewindow" || d === "togglefloating" || d === "fullscreen" || d === "layoutmsg" || d === "pseudo" || d === "pin" || d === "centerwindow" || d === "movefocus" || d === "cyclenext" || d === "focuswindow") {
                groupName = "Window Management"
            }
            
            var modsStr = b.mods_str !== undefined ? b.mods_str : root._maskToMods(b.modmask)
            var k = b.key
            if (k === "") k = "Unknown"
            var bindStr = modsStr ? (modsStr + " + " + k) : k
            var desc = b.description || b.arg || "No description"
            
            groups[groupName].push({ bind: bindStr, desc: desc })
        }
        
        var res = []
        var order = ["Launch Applications", "Close / Exit", "Workspace Management", "Window Management", "Other"]
        for (var i = 0; i < order.length; i++) {
            if (groups[order[i]].length > 0) {
                res.push({ name: order[i], actions: groups[order[i]] })
            }
        }
        return res
    }
}
