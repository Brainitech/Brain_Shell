pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

QtObject {
    id: root

    readonly property string _shellDir: Quickshell.shellDir
    readonly property string _luaPath:  _shellDir + "/Brain_ShellKeybinds.lua"
    readonly property string _jsonPath: _shellDir + "/src/user_data/keybinds.json"

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
        "PowerMenu-toggle":   { mods: "SUPER",        key: "ESCAPE", label: "Arch Menu",            group: "Popups"         },
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
        "screenrec-on":       { mods: "ALT",          key: "F9",     label: "Screen Record",        group: "Quick Settings" },
    })

    property var keybinds: ({})

    // ── Hyprland binds cache ──────────────────────────────────────────────────
    // Refreshed each time a BindRow enters capture mode.
    property var _hyprBinds: []

    property var _hyprBindsProc: Process {
        command: ["hyprctl", "binds", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try   { root._hyprBinds = JSON.parse(text.trim()) }
                catch (e) { root._hyprBinds = [] }
            }
        }
    }

    function loadHyprBinds() {
        _hyprBindsProc.running = false
        _hyprBindsProc.running = true
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

    // Returns a short description of the conflicting Hyprland bind, or "".
    // Own shell binds (arg contains "qs ipc") are filtered out.
    function wouldConflictHypr(action, mods, key) {
        var mask = _modsToMask(mods)
        var k    = key.toLowerCase()
        for (var i = 0; i < root._hyprBinds.length; i++) {
            var b = root._hyprBinds[i]
            if (b.submap !== "")                        continue  // ignore submaps
            if (b.mouse)                                continue  // ignore mouse binds
            if (b.arg && b.arg.indexOf("qs ipc") >= 0) continue  // our own shell binds
            if (b.modmask === mask && (b.key || "").toLowerCase() === k) {
                var desc = b.dispatcher || ""
                if (b.arg) desc += ": " + b.arg.substring(0, 36)
                return desc || "Hyprland bind"
            }
        }
        return ""
    }

    // ── Internal duplicate detection ──────────────────────────────────────────
    readonly property var _comboMap: {
        var m = {}
        var ks = Object.keys(root.keybinds)
        for (var i = 0; i < ks.length; i++) {
            var b = root.keybinds[ks[i]]
            if (!b || !b.mods || !b.key) continue
            var combo = b.mods + "+" + b.key
            if (!m[combo]) m[combo] = [ks[i]]
            else           m[combo] = m[combo].concat([ks[i]])
        }
        return m
    }

    function isDuplicate(action) {
        var b = root.keybinds[action]
        if (!b || !b.mods || !b.key) return false
        var combo = b.mods + "+" + b.key
        return !!(root._comboMap[combo] && root._comboMap[combo].length > 1)
    }

    function conflictsWith(action) {
        var b = root.keybinds[action]
        if (!b || !b.mods || !b.key) return ""
        var list = root._comboMap[b.mods + "+" + b.key]
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
        var combo = mods + "+" + key
        var ks    = Object.keys(root.keybinds)
        for (var i = 0; i < ks.length; i++) {
            if (ks[i] === action) continue
            var b = root.keybinds[ks[i]]
            if (b && b.mods + "+" + b.key === combo)
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
                        if (saved[s].key  !== undefined) merged[s].key  = saved[s].key
                    }
                } catch(e) {}
                root.keybinds = merged
                root._writeFiles()
                root._ensureInclude()
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
            if (root.keybinds[k].mods !== defs[k].mods || root.keybinds[k].key !== defs[k].key)
                out[k] = { mods: root.keybinds[k].mods, key: root.keybinds[k].key }
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

    property var _reloadProc: Process {
        command: ["hyprctl", "reload"]
        running: false
    }

    // Brief delay lets the file writes flush before hyprctl re-reads them
    property var _reloadTimer: Timer {
        interval: 300
        repeat:   false
        onTriggered: {
            root._reloadProc.running = false
            root._reloadProc.running = true
        }
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
        var k = newKey.toUpperCase().trim()
        if (m === "" || k === "") return
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

    // ── File generation ───────────────────────────────────────────────────────
    property var _writeProc: Process { command: []; running: false }

    function _writeFiles() {
        var lua = _genLua()
        var le  = lua.replace(/\\/g, "\\\\").replace(/'/g, "'\\''")
        _writeProc.command = ["bash", "-c",
            "printf '%s' '" + le + "' > '" + root._luaPath + "'"]
        _writeProc.running = false
        _writeProc.running = true
    }

    function _grouped() {
        var groups = {}; var order = []
        var ks = Object.keys(root.keybinds)
        for (var i = 0; i < ks.length; i++) {
            var k = ks[i]; var b = root.keybinds[k]
            if (!b || !b.mods || !b.key) continue
            var g = b.group || "Other"
            if (!groups[g]) { groups[g] = []; order.push(g) }
            groups[g].push({ k: k, mods: b.mods, key: b.key, label: b.label })
        }
        return { groups: groups, order: order }
    }

    function _genLua() {
        var sd   = root._shellDir.replace(/"/g, "\\\"")
        var data = _grouped()
        var lines = [
            "-- ==============================================================================",
            "-- Brain Shell Keybinds",
            "-- Auto-generated by Quickshell. Do not edit manually.",
            "-- ==============================================================================",
            "",
            "local shell = \"" + sd + "\"",
            "",
            "-- ==============================================================================",
            "-- BrainShell Capture Submap (Disables all normal binds during recording)",
            "-- ==============================================================================",
            "hl.define_submap(\"BrainShell_clean\", function()",
            "    -- Emergency exit in case the shell crashes during capture",
            "    hl.bind(\"CTRL + ESCAPE\", function()",
            "        hl.dispatch(hl.dsp.exec_cmd(\"notify-send 'BrainShell' 'Emergency Exit: Keybinds re-enabled.'\"))",
            "        hl.dispatch(hl.dsp.submap(\"reset\"))",
            "    end, { description = \"Emergency return to global submap\" })",
            "end)",
            "",
            "-- ==============================================================================",
            "-- User Defined Bindings",
            "-- ==============================================================================",
            ""
        ]
        
        for (var gi = 0; gi < data.order.length; gi++) {
            var g = data.order[gi]
            lines.push("-- " + g)
            var entries = data.groups[g]
            for (var ei = 0; ei < entries.length; ei++) {
                var e = entries[ei]
                lines.push("hl.bind(\"" + e.mods + " + " + e.key + "\", hl.dsp.exec_cmd(\"qs ipc -c \" .. shell .. \" call " + e.k + " toggle\"))")
            }
            lines.push("")
        }
        return lines.join("\n")
    }

    // ── Auto-include in hyprland.lua ──────────────────────────────────────────
    property var _includeProc: Process { command: []; running: false }

    function _ensureInclude() {
        var lp = root._luaPath.replace(/"/g, "\\\"")
        _includeProc.command = ["bash", "-c", [
            "MARKER='Brain_ShellKeybinds'",
            "LUA=\"$HOME/.config/hypr/hyprland.lua\"",
            "if [ -f \"$LUA\" ] && ! grep -qF \"$MARKER\" \"$LUA\"; then",
            "  printf '\\n-- Brain_ShellKeybinds\\ndofile(\"" + lp + "\")\\n' >> \"$LUA\"",
            "fi",
        ].join("\n")]
        _includeProc.running = false
        _includeProc.running = true
    }

    Component.onCompleted: _loadProc.running = true
}
