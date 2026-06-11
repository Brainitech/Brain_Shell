import QtQuick
import QtQuick.Controls
import "../"
import "../../"

Item {
    id: root

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
        height: root.hasPending ? 44 : 0
        clip:   true
        color:  Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
        border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.20)
        border.width: root.hasPending ? 1 : 0
        radius: 8

        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 10 }
            spacing: 8
            visible: root.hasPending

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var n = Object.keys(root._pending).length
                    return n + " unsaved change" + (n > 1 ? "s" : "")
                }
                font.pixelSize: 11
                color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.70)
            }

            // Discard
            Rectangle {
                width: 62; height: 26; radius: 7
                color: _discardH.hovered ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                border.color: Qt.rgba(1,1,1,0.13); border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "Discard"; font.pixelSize: 10
                    color: Qt.rgba(1,1,1,0.48) }
                HoverHandler { id: _discardH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root._pending = {} }
            }

            // Save
            Rectangle {
                width: 62; height: 26; radius: 7
                color: _saveH.hovered
                    ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.28)
                    : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.16)
                border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.42)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "Save"; font.pixelSize: 10
                    font.weight: Font.Medium; color: Theme.active }
                HoverHandler { id: _saveH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root._applyPending() }
            }
        }
    }

    // ── Scrollable list ───────────────────────────────────────────────────────
    Flickable {
        anchors {
            top:         _saveBanner.bottom
            left:        parent.left
            right:       parent.right
            bottom:      parent.bottom
            leftMargin:  12
            rightMargin: 12
            bottomMargin: 12
            topMargin:   6
        }
        contentWidth:   width
        contentHeight:  _col.implicitHeight + 16
        clip:           true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 3; implicitHeight: 40; radius: 1.5
                color: Qt.rgba(1, 1, 1, 0.22)
            }
            background: Item {}
        }

        Column {
            id: _col
            width:   parent.width - 12
            spacing: 2

            Repeater {
                model: root._groups
                delegate: Column {
                    required property var modelData
                    required property int index
                    width:   _col.width
                    spacing: 2

                    Item {
                        width:  parent.width
                        height: index > 0 ? 30 : 16
                        Text {
                            anchors.bottom:       parent.bottom
                            anchors.bottomMargin: 4
                            text:           modelData.name
                            font.pixelSize: 9
                            font.weight:    Font.Bold
                            color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)
                        }
                    }

                    Repeater {
                        model: modelData.actions
                        delegate: BindRow {
                            id: _br
                            required property string modelData
                            width:        _col.width
                            action:       modelData
                            isCapturing:  root._capturing === modelData
                            pendingCombo: root._pending[modelData] || null
                            onRequestCapture: root._capturing = modelData
                            onReleaseCapture: root._capturing = ""
                            onCaptureAccepted: function(newMods, newKey) {
                                root._addPending(_br.action, newMods, newKey)
                            }
                        }
                    }
                }
            }
        }
    }
    // ── BindRow ───────────────────────────────────────────────────────────────
    component BindRow: Item {
        id: br

        property string action:      ""
        property bool   isCapturing: false
        property var    pendingCombo: null   // { mods, key } or null

        signal requestCapture()
        signal releaseCapture()
        signal captureAccepted(string newMods, string newKey)

        // Capture internals
        property int    _pressedMods: 0
        property string _liveMods:    ""
        property string capturedMods: ""
        property string capturedKey:  ""

        // Derived from service + pending
        readonly property var    _b:         KeybindService.keybinds[action]
        readonly property var    _def:       KeybindService._defaults[action]
        readonly property bool _isUnbound: br._pillText === "Unbound"
        readonly property bool   _isPending: br.pendingCombo !== null && br.pendingCombo !== undefined
        readonly property bool   _isDefault: {
            if (!br._def) return true
            var m = br._isPending ? br.pendingCombo.mods : (br._b ? br._b.mods : "")
            var k = br._isPending ? br.pendingCombo.key  : (br._b ? br._b.key  : "")
            return m === br._def.mods && k === br._def.key
        }
        readonly property string _bindText: {
            if (!br._b || br._b.key === "") return "Unbound"
            return br._b.mods ? br._b.mods + " + " + br._b.key : br._b.key
        }
        // Show pending value in the pill when set
        readonly property string _pillText: {
            if (br._isPending) {
                if (br.pendingCombo.key === "") return "Unbound"
                return br.pendingCombo.mods ? br.pendingCombo.mods + " + " + br.pendingCombo.key : br.pendingCombo.key
            }
            return br._bindText
		}
		readonly property bool   _savedDupe: KeybindService.isDuplicate(action)

        readonly property bool _interactive: root._capturing === "" || br.isCapturing

        // Live conflict: service binds → pending map → Hyprland binds (in that order)
        readonly property string _conflictLabel: {
            if (!br.capturedKey) return ""
            var c = KeybindService.wouldConflict(br.action, br.capturedMods, br.capturedKey)
            if (c !== "") return c
            // Cross-check against other pending entries
            var combo = br.capturedMods + "+" + br.capturedKey
            var pkeys = Object.keys(root._pending)
            for (var i = 0; i < pkeys.length; i++) {
                if (pkeys[i] === br.action) continue
                var p = root._pending[pkeys[i]]
                if (p.mods + "+" + p.key === combo) {
                    var lbl = KeybindService.keybinds[pkeys[i]]
                    return (lbl ? lbl.label : pkeys[i]) + " (pending)"
                }
            }
            return KeybindService.wouldConflictHypr(br.action, br.capturedMods, br.capturedKey)
        }
        readonly property bool _hasConflict: _conflictLabel !== ""

        height: isCapturing ? 58 : 36
        clip: true
        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        onIsCapturingChanged: {
            if (isCapturing) {
                br._pressedMods = 0
                br._liveMods    = ""
                br.capturedMods = ""
                br.capturedKey  = ""
                KeybindService.loadHyprBinds()   // refresh for conflict detection
                Qt.callLater(function() { _captureArea.forceActiveFocus() })
            }
        }

        // ── Background ────────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius: 8
            color: br.isCapturing
                ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
                : _rH.hovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
            border.color: br._savedDupe
                ? Qt.rgba(248/255, 113/255, 113/255, 0.35)
                : br.isCapturing
                    ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.20)
                    : "transparent"
            border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        // ── Invisible focus target for key capture ────────────────────────────
        Item {
            id: _captureArea
            anchors.fill: parent
            focus:   br.isCapturing
            visible: br.isCapturing

            Keys.onPressed: function(event) {
                event.accepted = true
                if (_isMod(event.key)) {
                    br._liveMods = _mods(event.modifiers)
                    return
                }
                br._pressedMods = event.modifiers
                br._liveMods    = _mods(event.modifiers)
            }

            Keys.onReleased: function(event) {
                event.accepted = true
                if (_isMod(event.key)) {
                    if (!br.capturedKey) br._liveMods = _mods(event.modifiers)
                    return
                }
                // Bare Escape = cancel without saving
                if (event.key === Qt.Key_Escape && br._pressedMods === Qt.NoModifier) {
                    br.releaseCapture()
                    return
                }
                var k = _keyName(event.key)
                if (k !== "") {
                    var m = _mods(br._pressedMods)
                    br.capturedMods = m
                    br.capturedKey  = k
                    // Auto-accept when valid: has mods, no service conflict,
                    // no pending-map conflict, no Hyprland conflict
                    if (m !== ""
                        && KeybindService.wouldConflict(br.action, m, k) === ""
                        && KeybindService.wouldConflictHypr(br.action, m, k) === ""
                        && !_hasPendingConflict(m, k)) {
                        br.captureAccepted(m, k)
                        br.releaseCapture()
                    }
                    // else: stay open, show conflict warning
                }
            }

            // Returns true if mods+key collides with any OTHER pending entry
            function _hasPendingConflict(mods, key) {
                var combo = mods + "+" + key
                var pkeys = Object.keys(root._pending)
                for (var i = 0; i < pkeys.length; i++) {
                    if (pkeys[i] === br.action) continue
                    var p = root._pending[pkeys[i]]
                    if (p.mods + "+" + p.key === combo) return true
                }
                return false
            }
        }

        // ── Normal display ────────────────────────────────────────────────────
        Item {
            anchors { top: parent.top; left: parent.left; right: parent.right
                      leftMargin: 10; rightMargin: 8 }
            height: 36
            visible: !br.isCapturing

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text:           br._b ? br._b.label : br.action
                font.pixelSize: 12
                color:          br._savedDupe ? "#f87171" : (br._isUnbound ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.68))
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 6

                // Saved duplicate warning
                Text {
                    visible: br._savedDupe
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "⚠ " + KeybindService.conflictsWith(br.action)
                    font.pixelSize: 9
                    color:          Qt.rgba(248/255, 113/255, 113/255, 0.75)
                }

				// Clear bind
                Rectangle {
                    visible: br._pillText !== "Unbound"
                    width: 22; height: 22; radius: 6
                    color: _clrH.hovered ? Qt.rgba(1,1,1,0.09) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "󰩺"; font.pixelSize: 11
                        color: _clrH.hovered ? "#ff4444" : Qt.rgba(1,1,1,0.28) }
                    HoverHandler { id: _clrH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        enabled: br._interactive
                        onClicked: {
                            root._addPending(br.action, "", "")
                        }
                    }
                }

                // Reset to default
                Rectangle {
                    visible: !br._isDefault
                    width: 22; height: 22; radius: 6
                    color: _rstH.hovered ? Qt.rgba(1,1,1,0.09) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "↺"; font.pixelSize: 11
                        color: _rstH.hovered ? Theme.active : Qt.rgba(1,1,1,0.28) }
                    HoverHandler { id: _rstH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        enabled: br._interactive
                        onClicked: {
                            if (br._isPending) {
                                // If the saved value is already default, just drop pending
                                var def = KeybindService._defaults[br.action]
                                if (br._b && br._b.mods === def.mods && br._b.key === def.key)
                                    root._clearPending(br.action)
                                else
                                    root._addPending(br.action, def.mods, def.key)
                            } else {
                                // No pending → immediate save (reset is always safe)
                                KeybindService.resetBinding(br.action)
                            }
                        }
                    }
                }

                // Binding pill — amber tint when a pending change is staged
                Rectangle {
                    height: 24; radius: 6
                    width:  _pillT.implicitWidth + 18
                    
                    color: br._isUnbound
                        ? Qt.rgba(1, 1, 1, 0.04)
                        : ((_pillH.hovered && br._interactive)
                            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.16)
                            : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.08))
                            
                    border.color: br._isUnbound
                        ? Qt.rgba(1, 1, 1, 0.1)
                        : (br._isPending
                            ? Qt.rgba(1.0, 0.74, 0.22, 0.55)
                            : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.24))
                            
                    border.width: 1
                    
                    opacity: br._interactive ? (br._isUnbound ? 0.7 : 1.0) : 0.4
                    
                    Behavior on color        { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on opacity      { NumberAnimation { duration: 120 } }

                    Text {
                        id: _pillT
                        anchors.centerIn: parent
                        text:           br._pillText
                        font.pixelSize: 10; font.family: "JetBrains Mono"
                        font.italic:    br._isUnbound 
                        
                        color: br._isUnbound 
                            ? Qt.rgba(1, 1, 1, 0.45) 
                            : (br._isPending ? Qt.rgba(1.0, 0.74, 0.22, 1.0) : Theme.active)
                            
                        Behavior on color { ColorAnimation { duration: 150 } }
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
                      leftMargin: 10; rightMargin: 8 }
            spacing: 0
            visible: br.isCapturing

            // Row 1: label + live capture pill + cancel
            Item {
                width: parent.width; height: 36

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text:           br._b ? br._b.label : br.action
                    font.pixelSize: 12
                    color:          Qt.rgba(1, 1, 1, 0.68)
                }

                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 6

                    // Live capture pill
                    Rectangle {
                        height: 24; radius: 6
                        width:  Math.max(120, _capT.implicitWidth + 18)
                        color:  Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.08)
                        border.color: br._hasConflict
                            ? Qt.rgba(248/255, 113/255, 113/255, 0.55)
                            : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b,
                                      br.capturedKey !== "" ? 0.40 : 0.18)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Text {
                            id: _capT
                            anchors.centerIn: parent
                            font.pixelSize: 10; font.family: "JetBrains Mono"
                            color: br._hasConflict
                                ? "#f87171"
                                : br.capturedKey !== ""
                                    ? Theme.active
                                    : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.45)
                            text: {
                                if (br.capturedKey !== "")
                                    return (br.capturedMods ? br.capturedMods + " + " : "") + br.capturedKey
                                if (br._liveMods !== "")
                                    return br._liveMods + " + ?"
                                return "Press a key..."
                            }
                        }
                    }

                    // Cancel — Escape also cancels
                    Rectangle {
                        width: 28; height: 24; radius: 6
                        color: _cnH.hovered ? Qt.rgba(1,1,1,0.09) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 10
                            color: Qt.rgba(1,1,1,0.38) }
                        HoverHandler { id: _cnH; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: br.releaseCapture() }
                    }
                }
            }

            // Row 2: conflict warning (fades in when there's a conflict)
            Item {
                width: parent.width; height: 22
                opacity: (br.capturedKey !== "" && br._hasConflict) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }

                Text {
                    anchors { left: parent.left; leftMargin: 2; verticalCenter: parent.verticalCenter }
                    text:           "⚠  Conflicts with: " + br._conflictLabel
                    font.pixelSize: 10
                    color:          "#f87171"
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
                   k === Qt.Key_NumLock  || k === Qt.Key_ScrollLock
        }

        function _mods(flags) {
            var p = []
            if (flags & Qt.MetaModifier)    p.push("SUPER")
            if (flags & Qt.ShiftModifier)   p.push("SHIFT")
            if (flags & Qt.ControlModifier) p.push("CTRL")
            if (flags & Qt.AltModifier)     p.push("ALT")
            return p.join(" + ")
        }

        function _keyName(k) {
            if (_isMod(k)) return ""
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
            return m[k] || ""
        }

        HoverHandler { id: _rH; enabled: !br.isCapturing }
    }
}
