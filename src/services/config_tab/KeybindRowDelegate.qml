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
    id: br
    property real localScale: 1.0

    property string action:       ""
    property bool   isCapturing:  false
    property var    pendingCombo: null   // { mods, key } or null
    property var    pendingMap:   ({})
    property bool   anyCapturing: false

    signal requestCapture()
    signal releaseCapture()
    signal captureAccepted(string newMods, string newKey)
    signal clearRequested(string action)
    signal resetRequested(string action)

    // Capture internals
    property int    _pressedMods: 0
    property string _liveMods:    ""
    property string capturedMods: ""
    property string capturedKey:  ""
    property int    _lastModKey:  0
    property int    _lastModScan: 0
    property bool   _hadNonMod:   false

    // Derived from service + pending
    readonly property var    _b:         KeybindService.keybinds[action]
    readonly property var    _def:       KeybindService._defaults[action]
    readonly property bool   _isUnbound: br._pillText === "Unbound"
    readonly property bool   _isPending: br.pendingCombo !== null && br.pendingCombo !== undefined
    readonly property bool   _isDefault: {
        if (!br._def) return true
        var m = br._isPending ? br.pendingCombo.mods : (br._b ? br._b.mods : "")
        var k = br._isPending ? br.pendingCombo.key  : (br._b ? br._b.key  : "")
        return m === br._def.mods && k === br._def.key
    }
    readonly property string _bindText: {
        if (!br._b || br._b.key === "") return "Unbound"
        var k = br._displayKey(br._b.key)
        return br._b.mods ? br._b.mods + " + " + k : k
    }
    // Show pending value in the pill when set
    readonly property string _pillText: {
        if (br._isPending) {
            if (br.pendingCombo.key === "") return "Unbound"
            var k = br._displayKey(br.pendingCombo.key)
            return br.pendingCombo.mods ? br.pendingCombo.mods + " + " + k : k
        }
        return br._bindText
    }
    readonly property bool   _savedDupe: KeybindService.isDuplicate(action)

    readonly property bool   _interactive: !br.anyCapturing || br.isCapturing

    // Live conflict: service binds → pending map → Hyprland binds (in that order)
    readonly property string _conflictLabel: {
        if (!br.capturedKey || br.capturedKey.toUpperCase() === "UNKNOWN") return ""
        var c = KeybindService.wouldConflict(br.action, br.capturedMods, br.capturedKey)
        if (c !== "") return c
        // Cross-check against other pending entries
        var myEffMods = KeybindService._effectiveMods(br.capturedMods, br.capturedKey)
        var myKey = KeybindService._normalizeKey(br.capturedKey).toUpperCase()
        var combo = KeybindService._modsToMask(myEffMods) + "+" + myKey
        var pkeys = Object.keys(br.pendingMap || {})
        for (var i = 0; i < pkeys.length; i++) {
            if (pkeys[i] === br.action) continue
            var p = br.pendingMap[pkeys[i]]
            if (!p) continue
            var pEffMods = KeybindService._effectiveMods(p.mods, p.key)
            var pKey = KeybindService._normalizeKey(p.key).toUpperCase()
            if (KeybindService._modsToMask(pEffMods) + "+" + pKey === combo) {
                var lbl = KeybindService.keybinds[pkeys[i]]
                return (lbl ? lbl.label : pkeys[i]) + " (pending)"
            }
        }
        return KeybindService.wouldConflictCompositor(br.action, br.capturedMods, br.capturedKey)
    }
    readonly property bool _hasConflict: _conflictLabel !== ""

    height: isCapturing ? Math.round(58 * localScale) : Math.round(36 * localScale)
    clip: true
    Behavior on height { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod} }

    onIsCapturingChanged: {
        if (isCapturing) {
            br._pressedMods = 0
            br._liveMods    = ""
            br._lastModKey  = 0
            br._lastModScan = 0
            br._hadNonMod   = false
            br.capturedMods = ""
            br.capturedKey  = ""
            KeybindService.loadCompositorBinds()   // refresh for conflict detection
            Qt.callLater(function() { _captureArea.forceActiveFocus() })
        }
    }

    // ── Background ────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Math.round(8 * localScale)
        color: br.isCapturing
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
            : _rH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04) : "transparent"
        border.color: br._savedDupe
            ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.35)
            : br.isCapturing
                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.20)
                : "transparent"
        border.width: 1
        Behavior on color { ColorAnimation { duration: Anim.color} }
    }

    // ── Invisible focus target for key capture ────────────────────────────
    Item {
        id: _captureArea
        anchors.fill: parent
        focus:   br.isCapturing
        visible: br.isCapturing

        Keys.onPressed: function(event) {
            event.accepted = true
            if (br._isMod(event.key)) {
                br._lastModKey  = (event.key === Qt.Key_Multi_key) ? Qt.Key_Control : event.key
                br._lastModScan = event.nativeScanCode
                br._liveMods    = br._mods(event.modifiers)
                return
            }
            br._hadNonMod   = true
            br._pressedMods = event.modifiers
            br._liveMods    = br._mods(event.modifiers)
        }

        Keys.onReleased: function(event) {
            event.accepted = true
            var key = event.key
            var scan = event.nativeScanCode

            // Check for solo modifier release
            // On Wayland, modifier release events often report event.key as 0 (Qt.Key_unknown)
            var isModRelease = br._isMod(key) || (key === 0 && br._lastModKey !== 0)
            if (isModRelease) {
                var targetKey = (key !== 0 && key !== Qt.Key_unknown) ? key : br._lastModKey
                if (targetKey === Qt.Key_Multi_key) targetKey = Qt.Key_Control
                var targetScan = (scan !== 0) ? scan : br._lastModScan

                if (!br._hadNonMod && br._isSoloMod(event, targetKey) && br.capturedKey === "") {
                    var modKey = br._modKeyName(targetKey, targetScan)
                    if (modKey !== "") {
                        var m = ""
                        var k = modKey
                        br.capturedMods = m
                        br.capturedKey  = k
                        if (KeybindService.wouldConflict(br.action, m, k) === ""
                            && KeybindService.wouldConflictCompositor(br.action, m, k) === ""
                            && !_hasPendingConflict(m, k)) {
                            br.captureAccepted(m, k)
                            br.releaseCapture()
                        }
                        return
                    }
                }
                if (!br.capturedKey) br._liveMods = br._mods(event.modifiers)
                return
            }

            // Bare Escape = cancel without saving
            if (key === Qt.Key_Escape && br._pressedMods === Qt.NoModifier) {
                br.releaseCapture()
                return
            }

            // Non-modifier key release
            var k = br._keyName(event)
            if (k !== "" && k.toUpperCase() !== "UNKNOWN") {
                var m = br._mods(br._pressedMods)
                br.capturedMods = m
                br.capturedKey  = k
                // Auto-accept when valid: no service conflict,
                // no pending-map conflict, no compositor conflict
                if (KeybindService.wouldConflict(br.action, m, k) === ""
                    && KeybindService.wouldConflictCompositor(br.action, m, k) === ""
                    && !_hasPendingConflict(m, k)) {
                    br.captureAccepted(m, k)
                    br.releaseCapture()
                }
                // else: stay open, show conflict warning
            }
        }

        // Returns true if mods+key collides with any OTHER pending entry
        function _hasPendingConflict(mods, key) {
            var myEffMods = KeybindService._effectiveMods(mods, key)
            var myKey = KeybindService._normalizeKey(key).toUpperCase()
            var combo = KeybindService._modsToMask(myEffMods) + "+" + myKey
            var pkeys = Object.keys(br.pendingMap || {})
            for (var i = 0; i < pkeys.length; i++) {
                if (pkeys[i] === br.action) continue
                var p = br.pendingMap[pkeys[i]]
                if (!p) continue
                var pEffMods = KeybindService._effectiveMods(p.mods, p.key)
                var pKey = KeybindService._normalizeKey(p.key).toUpperCase()
                if (KeybindService._modsToMask(pEffMods) + "+" + pKey === combo) return true
            }
            return false
        }
    }

    // ── Normal display ────────────────────────────────────────────────────
    Item {
        anchors { top: parent.top; left: parent.left; right: parent.right
                  leftMargin: Math.round(10 * localScale); rightMargin: Math.round(8 * localScale) }
        height: Math.round(36 * localScale)
        visible: !br.isCapturing

        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text:           br._b ? br._b.label : br.action
            font.pixelSize: Math.round(12 * localScale)
            color:          br._savedDupe ? Theme.error : (br._isUnbound ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.68))
            Behavior on color { ColorAnimation { duration: Anim.color} }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: Math.round(6 * localScale)

            // Saved duplicate warning
            Text {
                visible: br._savedDupe
                anchors.verticalCenter: parent.verticalCenter
                text:           "⚠ " + KeybindService.conflictsWith(br.action)
                font.pixelSize: Math.round(9 * localScale)
                color:          Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.75)
            }

            // Clear bind
            Rectangle {
                visible: br._pillText !== "Unbound"
                width: Math.round(22 * localScale); height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: _clrH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.09) : "transparent"
                Behavior on color { ColorAnimation { duration: Anim.fast} }
                Text { anchors.centerIn: parent; text: "󰩺"; font.pixelSize: Math.round(11 * localScale)
                    color: _clrH.hovered ? "#ff4444" : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.28) }
                HoverHandler { id: _clrH; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    enabled: br._interactive
                    onClicked: {
                        br.clearRequested(br.action)
                    }
                }
            }

            // Reset to default
            Rectangle {
                visible: !br._isDefault
                width: Math.round(22 * localScale); height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: _rstH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.09) : "transparent"
                Behavior on color { ColorAnimation { duration: Anim.fast} }
                Text { anchors.centerIn: parent; text: "↺"; font.pixelSize: Math.round(11 * localScale)
                    color: _rstH.hovered ? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.28) }
                HoverHandler { id: _rstH; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    enabled: br._interactive
                    onClicked: {
                        br.resetRequested(br.action)
                    }
                }
            }

            // Binding pill — amber tint when a pending change is staged
            Rectangle {
                height: Math.round(24 * localScale); radius: Math.round(6 * localScale)
                width:  _pillT.implicitWidth + Math.round(18 * localScale)
                
                color: br._isUnbound
                    ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                    : ((_pillH.hovered && br._interactive)
                        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.16)
                        : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.08))
                        
                border.color: br._isUnbound
                    ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                    : (br._isPending
                        ? Qt.rgba(1.0, 0.74, 0.22, 0.55)
                        : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.24))
                        
                border.width: 1
                
                opacity: br._interactive ? (br._isUnbound ? 0.7 : 1.0) : 0.4
                
                Behavior on color        { ColorAnimation { duration: Anim.fast} }
                Behavior on border.color { ColorAnimation { duration: Anim.mediumFast} }
                Behavior on opacity      { NumberAnimation { duration: Anim.color} }

                Text {
                    id: _pillT
                    anchors.centerIn: parent
                    text:           br._pillText
                    font.pixelSize: Math.round(10 * localScale); font.family: "JetBrains Mono"
                    font.italic:    br._isUnbound 
                    
                    color: br._isUnbound 
                        ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45) 
                        : (br._isPending ? Qt.rgba(1.0, 0.74, 0.22, 1.0) : Theme.active)
                        
                    Behavior on color { ColorAnimation { duration: Anim.mediumFast} }
                }
                HoverHandler { id: _pillH; cursorShape: br._interactive ? Qt.PointingHandCursor : Qt.ArrowCursor }
                MouseArea {
                    anchors.fill: parent
                    enabled: br._interactive
                    onClicked: br.requestCapture()
                }
            }
        }
    }

    // ── Capture display ───────────────────────────────────────────────────
    Column {
        anchors { top: parent.top; left: parent.left; right: parent.right
                  leftMargin: Math.round(10 * localScale); rightMargin: Math.round(8 * localScale) }
        spacing: 0
        visible: br.isCapturing

        // Row 1: label + live capture pill + cancel
        Item {
            width: parent.width; height: Math.round(36 * localScale)

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text:           br._b ? br._b.label : br.action
                font.pixelSize: Math.round(12 * localScale)
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.68)
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Math.round(6 * localScale)

                // Live capture pill
                Rectangle {
                    height: Math.round(24 * localScale); radius: Math.round(6 * localScale)
                    width:  Math.max(Math.round(120 * localScale), _capT.implicitWidth + Math.round(18 * localScale))
                    color:  Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.08)
                    border.color: br._hasConflict
                        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.55)
                        : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b,
                                  br.capturedKey !== "" ? 0.40 : 0.18)
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: Anim.color} }

                    Text {
                        id: _capT
                        anchors.centerIn: parent
                        font.pixelSize: Math.round(10 * localScale); font.family: "JetBrains Mono"
                        color: br._hasConflict
                            ? Theme.error
                            : br.capturedKey !== ""
                                ? Theme.active
                                : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.45)
                        text: {
                            if (br.capturedKey !== "" && br.capturedKey.toUpperCase() !== "UNKNOWN")
                                return (br.capturedMods ? br.capturedMods + " + " : "") + br._displayKey(br.capturedKey)
                            if (br._liveMods !== "")
                                return br._liveMods + " + ?"
                            return "Press a key..."
                        }
                    }
                }

                // Cancel — Escape also cancels
                Rectangle {
                    width: 28; height: Math.round(24 * localScale); radius: Math.round(6 * localScale)
                    color: _cnH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.09) : "transparent"
                    Behavior on color { ColorAnimation { duration: Anim.fast} }
                    Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: Math.round(10 * localScale)
                        color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.38) }
                    HoverHandler { id: _cnH; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: br.releaseCapture() }
                }
            }
        }

        // Row 2: conflict warning & resolution dialog
        KeybindConflictDialog {
            id: conflictDialog
            width: parent.width
            height: Math.round(22 * br.localScale)
            localScale: br.localScale
            conflictLabel: br._conflictLabel
            active: br.capturedKey !== "" && br._hasConflict
            onDismissed: br.releaseCapture()
            onOverrideAccepted: {
                br.captureAccepted(br.capturedMods, br.capturedKey)
                br.releaseCapture()
            }
        }
    }

    // ── Key helpers ───────────────────────────────────────────────────────
    function _isMod(k) {
        return k === Qt.Key_Shift    || k === Qt.Key_Control  ||
               k === Qt.Key_Meta     || k === Qt.Key_Alt      ||
               k === Qt.Key_Super_L  || k === Qt.Key_Super_R  ||
               k === Qt.Key_Hyper_L  || k === Qt.Key_Hyper_R  ||
               k === Qt.Key_AltGr    || k === Qt.Key_CapsLock ||
               k === Qt.Key_NumLock  || k === Qt.Key_ScrollLock ||
               k === Qt.Key_Multi_key
    }

    function _modKeyName(k, scan) {
        if (k === Qt.Key_Super_L || k === Qt.Key_Meta) {
            if (scan === 126 || scan === 134) return "SUPER_R"
            return "SUPER_L"
        }
        if (k === Qt.Key_Super_R)                     return "SUPER_R"
        if (k === Qt.Key_Alt) {
            if (scan === 100 || scan === 108) return "Alt_R"
            return "Alt_L"
        }
        if (k === Qt.Key_AltGr)                       return "Alt_R"
        if (k === Qt.Key_Control || k === Qt.Key_Multi_key) {
            if (scan === 97 || scan === 105) return "Control_R"
            return "Control_L"
        }
        if (k === Qt.Key_Shift) {
            if (scan === 54 || scan === 62) return "Shift_R"
            return "Shift_L"
        }
        return ""
    }

    function _isSoloMod(event, targetKey) {
        var k = targetKey || event.key
        var mods = event.modifiers
        if (k === Qt.Key_Super_L || k === Qt.Key_Super_R || k === Qt.Key_Meta) {
            return (mods & (Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier)) === 0
        }
        if (k === Qt.Key_Alt || k === Qt.Key_AltGr) {
            return (mods & (Qt.ShiftModifier | Qt.ControlModifier | Qt.MetaModifier)) === 0
        }
        if (k === Qt.Key_Control || k === Qt.Key_Multi_key) {
            return (mods & (Qt.ShiftModifier | Qt.AltModifier | Qt.MetaModifier)) === 0
        }
        if (k === Qt.Key_Shift) {
            return (mods & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) === 0
        }
        return false
    }

    function _displayKey(k) {
        if (!k) return ""
        var u = k.toUpperCase()
        if (u === "UNKNOWN")                    return ""
        if (u === "SUPER_L" || u === "SUPER")   return "SUPER"
        if (u === "SUPER_R")                    return "SUPER_R"
        if (u === "ALT_L" || u === "ALT")       return "ALT"
        if (u === "ALT_R" || u === "ALTGR")     return "ALT_R"
        if (u === "CONTROL_L" || u === "CTRL")  return "CTRL"
        if (u === "CONTROL_R")                  return "CTRL_R"
        if (u === "SHIFT_L" || u === "SHIFT")   return "SHIFT"
        if (u === "SHIFT_R")                    return "SHIFT_R"
        return k
    }

    function _mods(flags) {
        var p = []
        if (flags & Qt.MetaModifier)    p.push("SUPER")
        if (flags & Qt.ShiftModifier)   p.push("SHIFT")
        if (flags & Qt.ControlModifier) p.push("CTRL")
        if (flags & Qt.AltModifier)     p.push("ALT")
        return p.join(" + ")
    }

    function _keyName(event) {
        var k = event.key
        if (k === 0 || k === Qt.Key_unknown || _isMod(k)) return ""
        if (k >= Qt.Key_A && k <= Qt.Key_Z)    return String.fromCharCode(k)
        if (k >= Qt.Key_0 && k <= Qt.Key_9)    return String.fromCharCode(k)
        if (k >= Qt.Key_F1 && k <= Qt.Key_F35) return "F" + (k - Qt.Key_F1 + 1)
        var m = {}
        m[Qt.Key_Escape]       = "Escape"
        m[Qt.Key_Return]       = "Return"
        m[Qt.Key_Enter]        = "KP_Enter"
        m[Qt.Key_Tab]          = "Tab"
        m[Qt.Key_Backspace]    = "BackSpace"
        m[Qt.Key_Delete]       = "Delete"
        m[Qt.Key_Insert]       = "Insert"
        m[Qt.Key_Home]         = "Home"
        m[Qt.Key_End]          = "End"
        m[Qt.Key_PageUp]       = "Prior"
        m[Qt.Key_PageDown]     = "Next"
        m[Qt.Key_Left]         = "Left"
        m[Qt.Key_Right]        = "Right"
        m[Qt.Key_Up]           = "Up"
        m[Qt.Key_Down]         = "Down"
        m[Qt.Key_Space]        = "Space"
        m[Qt.Key_Print]        = "Print"
        m[Qt.Key_Pause]        = "Pause"
        m[Qt.Key_Minus]        = "minus"
        m[Qt.Key_Equal]        = "equal"
        m[Qt.Key_BracketLeft]  = "bracketleft"
        m[Qt.Key_BracketRight] = "bracketright"
        m[Qt.Key_Backslash]    = "backslash"
        m[Qt.Key_Semicolon]    = "semicolon"
        m[Qt.Key_Apostrophe]   = "apostrophe"
        m[Qt.Key_Comma]        = "comma"
        m[Qt.Key_Period]       = "period"
        m[Qt.Key_Slash]        = "slash"
        m[Qt.Key_QuoteLeft]    = "grave"
        m[Qt.Key_VolumeUp]       = "XF86AudioRaiseVolume"
        m[Qt.Key_VolumeDown]     = "XF86AudioLowerVolume"
        m[Qt.Key_VolumeMute]     = "XF86AudioMute"
        m[Qt.Key_MediaPlay]      = "XF86AudioPlay"
        m[Qt.Key_MediaPause]     = "XF86AudioPause"
        m[Qt.Key_MediaTogglePlayPause] = "XF86AudioPlay"
        m[Qt.Key_MediaNext]      = "XF86AudioNext"
        m[Qt.Key_MediaPrevious]  = "XF86AudioPrev"
        m[Qt.Key_MonBrightnessUp]   = "XF86MonBrightnessUp"
        m[Qt.Key_MonBrightnessDown] = "XF86MonBrightnessDown"
        if (m[k]) return m[k]
        if (event.text && event.text !== "") {
            var t = event.text.toUpperCase()
            if (t >= " " && t <= "~") return t
        }
        return ""
    }

    HoverHandler { id: _rH; enabled: !br.isCapturing }
}
