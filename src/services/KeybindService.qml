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

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

QtObject {
    id: root

    readonly property string _jsonPath: Paths.userDataDir + "/keybinds.json"

    // ── Capture gate ──────────────────────────────────────────────────────────
    // Set true by KeybindsPage while a combo is being recorded.
    // In your state handler (ShellState / Popups), observe this and dispatch:
    //   true  →  hyprctl dispatch submap, clean
    //   false →  hyprctl dispatch submap, reset
    property bool isCapturing: false

    // ── Defaults ──────────────────────────────────────────────────────────────
    readonly property var _defaults: ({
        "dashboard-home":     { mods: "SUPER",        key: "D",      label: "Dashboard: System",    group: "Dashboard"      },
        "dashboard-stats":    { mods: "CTRL + SHIFT",  key: "ESCAPE", label: "Dashboard: Home",      group: "Dashboard"      },
        "dashboard-kanban":   { mods: "SUPER",        key: "Z",      label: "Dashboard: Tasks",     group: "Dashboard"      },
        "dashboard-launcher": { mods: "SUPER",        key: "Q",      label: "Dashboard: Apps",      group: "Dashboard"      },
        "dashboard-config":   { mods: "SUPER",        key: "C",      label: "Dashboard: Config",    group: "Dashboard"      },
        "PowerMenu-toggle":   { mods: "SUPER",        key: "ESCAPE", label: "Power Menu",            group: "Popups"         },
        "notification-toggle":{ mods: "SUPER",        key: "N",      label: "Notifications",        group: "Popups"         },
        "wallpaper-toggle":   { mods: "SUPER",        key: "W",      label: "Wallpaper",            group: "Popups"         },
        "clipboard-toggle":   { mods: "SUPER",        key: "V",      label: "Clipboard",            group: "Popups"         },
        "wifi-toggle":        { mods: "SUPER + ALT",   key: "W",      label: "Network: Wi-Fi",       group: "Network Tabs"   },
        "bluetooth-toggle":   { mods: "SUPER + ALT",   key: "B",      label: "Network: Bluetooth",   group: "Network Tabs"   },
        "vpn-toggle":         { mods: "SUPER + ALT",   key: "G",      label: "Network: VPN",         group: "Network Tabs"   },
        "hotspot-toggle":     { mods: "SUPER + ALT",   key: "H",      label: "Network: Hotspot",     group: "Network Tabs"   },
        "audioOut-toggle":    { mods: "SUPER",        key: "A",      label: "Audio: Output",        group: "Audio Tabs"     },
        "audioIn-toggle":     { mods: "SUPER + ALT",   key: "I",      label: "Audio: Input",         group: "Audio Tabs"     },
        "audioMix-toggle":    { mods: "SUPER",        key: "M",      label: "Audio: Mixer",         group: "Audio Tabs"     },
        "focus-toggle":       { mods: "SUPER",        key: "B",      label: "Focus Mode",           group: "Quick Settings" },
        "lock-session":       { mods: "SUPER",        key: "X",      label: "Lock Screen",          group: "Quick Settings" },
        "screenshot-toggle":  { mods: "",             key: "PRINT",  label: "Screenshot",           group: "Quick Settings" },
        "screenrec-on":       { mods: "ALT",          key: "F9",     label: "Screen Record",        group: "Quick Settings" },
    })

    property var keybinds: ({})

    readonly property var compositorBinds: WM.rawKeybinds

    function loadCompositorBinds() {
        WM.loadRawKeybinds()
    }

    // Converts "SUPER + SHIFT" → Hyprland modmask integer
    function _modsToMask(modsStr) {
        var mask = 0
        var parts = modsStr.toUpperCase().split("+")
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim()
            if      (p === "SUPER") mask |= 64
            else if (p === "SHIFT") mask |= 1
            else if (p === "CTRL")  mask |= 4
            else if (p === "ALT")   mask |= 8
        }
        return mask
    }

    function _isModKey(key) {
        if (!key) return false
        var u = key.toUpperCase().trim()
        return u === "SUPER_L" || u === "SUPER_R" ||
               u === "ALT_L"   || u === "ALT_R"   ||
               u === "CONTROL_L" || u === "CONTROL_R" ||
               u === "SHIFT_L" || u === "SHIFT_R" ||
               u === "SUPER"   || u === "ALT"     ||
               u === "CTRL"    || u === "SHIFT"
    }

    function _modForModKey(key) {
        if (!key) return ""
        var u = key.toUpperCase().trim()
        if (u === "SUPER_L" || u === "SUPER_R" || u === "SUPER") return "SUPER"
        if (u === "ALT_L" || u === "ALT_R" || u === "ALT" || u === "ALTGR") return "ALT"
        if (u === "CONTROL_L" || u === "CONTROL_R" || u === "CTRL_L" || u === "CTRL_R" || u === "CTRL") return "CTRL"
        if (u === "SHIFT_L" || u === "SHIFT_R" || u === "SHIFT") return "SHIFT"
        return ""
    }

    function _normalizeKey(key) {
        if (!key) return ""
        var s = key.trim()
        var u = s.toUpperCase()
        if (u === "UNKNOWN")                                      return ""
        if (u === "SUPER_L" || u === "SUPER")                     return "SUPER_L"
        if (u === "SUPER_R")                                      return "SUPER_R"
        if (u === "ALT_L" || u === "ALT")                         return "Alt_L"
        if (u === "ALT_R" || u === "ALTGR")                       return "Alt_R"
        if (u === "CONTROL_L" || u === "CTRL_L" || u === "CTRL") return "Control_L"
        if (u === "CONTROL_R" || u === "CTRL_R")                  return "Control_R"
        if (u === "SHIFT_L" || u === "SHIFT")                     return "Shift_L"
        if (u === "SHIFT_R")                                      return "Shift_R"
        return u
    }

    function _effectiveMods(mods, key) {
        if ((!mods || mods === "") && root._isModKey(key)) {
            return root._modForModKey(key)
        }
        return mods || ""
    }

    // Returns a short description of the conflicting compositor bind, or "".
    // Own shell binds (arg contains "qs ipc") are filtered out.
    function wouldConflictCompositor(action, mods, key) {
        return WM.wouldConflictCompositor(action, mods, key)
    }


    readonly property var _comboMap: {
        var m = {}
        var ks = Object.keys(root.keybinds)
        for (var i = 0; i < ks.length; i++) {
            var b = root.keybinds[ks[i]]
            if (!b || !b.key || b.key === "") continue
            var combo = root._modsToMask(root._effectiveMods(b.mods, b.key)) + "+" + root._normalizeKey(b.key).toUpperCase()
            if (!m[combo]) m[combo] = [ks[i]]
            else           m[combo] = m[combo].concat([ks[i]])
        }
        return m
    }

    function isDuplicate(action) {
        var b = root.keybinds[action]
        if (!b || !b.key || b.key === "") return false
        var combo = root._modsToMask(root._effectiveMods(b.mods, b.key)) + "+" + root._normalizeKey(b.key).toUpperCase()
        return !!(root._comboMap[combo] && root._comboMap[combo].length > 1)
    }

    function conflictsWith(action) {
        var b = root.keybinds[action]
        if (!b || !b.key || b.key === "") return ""
        var combo = root._modsToMask(root._effectiveMods(b.mods, b.key)) + "+" + root._normalizeKey(b.key).toUpperCase()
        var list = root._comboMap[combo]
        if (!list || list.length < 2) return ""
        for (var i = 0; i < list.length; i++) {
            if (list[i] !== action) {
                var o = root.keybinds[list[i]]
                return o ? o.label : list[i]
            }
        }
        return ""
    }

    function wouldConflict(action, mods, key) {
        if (!key || key === "") return ""
        var mask = root._modsToMask(root._effectiveMods(mods, key))
        var k = root._normalizeKey(key).toUpperCase()
        var ks = Object.keys(root.keybinds)
        for (var i = 0; i < ks.length; i++) {
            if (ks[i] === action) continue
            var b = root.keybinds[ks[i]]
            if (b && b.key && root._modsToMask(root._effectiveMods(b.mods, b.key)) === mask && root._normalizeKey(b.key).toUpperCase() === k)
                return b.label || ks[i]
        }
        return ""
    }

    // ── Load ──────────────────────────────────────────────────────────────────
    property var _loadProc: Process {
        command: ["bash", "-c",
            "[ -f '" + root._jsonPath + "' ] && cat '" + root._jsonPath + "' || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var merged = {}
                var defs   = root._defaults
                var dkeys  = Object.keys(defs)
                for (var i = 0; i < dkeys.length; i++) {
                    var dk = dkeys[i]
                    merged[dk] = { mods: defs[dk].mods, key: defs[dk].key,
                                   label: defs[dk].label, group: defs[dk].group }
                }
                try {
                    var saved = JSON.parse(text.trim())
                    var sk = Object.keys(saved)
                    for (var j = 0; j < sk.length; j++) {
                        var s = sk[j]
                        if (!merged[s]) continue
                        if (saved[s].mods !== undefined) merged[s].mods = saved[s].mods
                        if (saved[s].key  !== undefined) merged[s].key  = root._normalizeKey(saved[s].key)
                    }
                } catch(e) {}
                root.keybinds = merged
                root._writeFiles()
            }
        }
    }

    // ── Save / Reload ─────────────────────────────────────────────────────────
    function save() {
        var out  = {}
        var defs = root._defaults
        var ks   = Object.keys(root.keybinds)
        for (var i = 0; i < ks.length; i++) {
            var k = ks[i]
            if (!defs[k]) continue
            var b = root.keybinds[k]
            if (!b || !b.key || b.key === "" || b.key.toUpperCase() === "UNKNOWN") continue
            if (b.mods !== defs[k].mods || b.key !== defs[k].key)
                out[k] = { mods: b.mods, key: b.key }
        }
        var json = JSON.stringify(out, null, 2)
        _saveProc.command = ["bash", "-c",
            "mkdir -p \"$(dirname '" + root._jsonPath + "')\" && " +
            "printf '%s' '" + json.replace(/'/g, "'\\''") + "' > '" + root._jsonPath + "'"]
        _saveProc.running = false
        _saveProc.running = true
        root._writeFiles()
    }

    property var _saveProc: Process { command: []; running: false }

    // Brief delay lets the file writes flush before compositor re-reads them
    property var _reloadTimer: Timer {
        interval: 300
        repeat:   false
        onTriggered: WM.reloadConfig()
    }

    function reload() {
        _reloadTimer.restart()
    }

    // Persist to disk and reload Hyprland in one call
    function saveAndReload() {
        save()
        reload()
    }

    // Updates in-memory only — does NOT persist.
    // Callers responsible for invoking saveAndReload() when ready.
    function updateBinding(action, newMods, newKey) {
        var old = root.keybinds[action]
        if (!old) return
        var m = newMods.toUpperCase().trim()
        var k = root._normalizeKey(newKey)
        if (k === "") return
        if (root.wouldConflict(action, m, k) !== "") return
        var copy     = Object.assign({}, root.keybinds)
        copy[action] = { mods: m, key: k, label: old.label, group: old.group }
        root.keybinds = copy
    }

    // Reset is always immediate — reverts to default and reloads right away
    function resetBinding(action) {
        var def = root._defaults[action]
        if (!def) return
        updateBinding(action, def.mods, def.key)
        saveAndReload()
    }

	// Allows the UI to explicitly unbind an action (or preserve installer unbinds)
    function unbindBinding(action) {
        var old = root.keybinds[action]
        if (!old) return
        
        var copy = Object.assign({}, root.keybinds)
        copy[action] = { mods: "", key: "", label: old.label, group: old.group }
        root.keybinds = copy
        
        saveAndReload()
    }

    // ── File generation ───────────────────────────────────────────────────────
    function _writeFiles() {
        WM.writeKeybindFiles(root.keybinds)
    }

    Component.onCompleted: _loadProc.running = true
}
