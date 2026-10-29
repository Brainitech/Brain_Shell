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
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    // ── Identity ──────────────────────────────────────────────────────────────
    readonly property string name: "Niri"
    readonly property bool isSupported: {
        var forced = Quickshell.env("BRAIN_SHELL_WM")
        if (typeof forced === "string" && forced.trim() !== "") {
            return forced.trim().toLowerCase() === "niri"
        }
        var hasNiri = typeof Quickshell.env("NIRI_SOCKET") === "string" && Quickshell.env("NIRI_SOCKET").trim() !== ""
        if (hasNiri) return true
        var desk = (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toString().toLowerCase()
        return desk.indexOf("niri") !== -1
    }
    property string configProvider: "kdl"

    // ── Signals ───────────────────────────────────────────────────────────────
    signal activeWindowChanged(string title, string initialTitle, string windowClass)
    signal workspaceChanged()
    signal scratchpadChanged(bool active)
    signal dismissRequested()
    signal configReloaded()

    // ── Displays & Monitors ───────────────────────────────────────────────────
    property string focusedMonitorName: ""

    // ── Workspaces ────────────────────────────────────────────────────────────
    property var workspaces: []
    property var focusedWorkspace: ({ id: 1, rawId: 1, name: "1" })
    property int focusedWorkspaceId: 1
    readonly property bool isScratchpad: false

    property var _rawWorkspaces: []
    property var _rawWindows: []
    property var _focusedWindowId: null

    property Process switchWsProc: Process {
        running: false
    }

    function switchWorkspace(wsTarget, isSpecialToggle = false) {
        if (!root.isSupported) return
        switchWsProc.command = ["niri", "msg", "action", "focus-workspace", String(wsTarget)]
        switchWsProc.running = true
    }

    function toggleScratchpad(name = "magic") {}

    function cycleWorkspace(direction = 1) {
        if (!root.isSupported) return
        switchWsProc.command = ["niri", "msg", "action", direction > 0 ? "focus-workspace-down" : "focus-workspace-up"]
        switchWsProc.running = true
    }

    // ── Active Window Tracking ────────────────────────────────────────────────
    property string activeTitle: "Desktop"
    property string activeInitialTitle: "Desktop"
    property string activeClass: ""

    property Process focusedWinProc: Process {
        command: ["niri", "msg", "-j", "focused-window"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim()
                if (out === "" || out === "null" || out === "{}") {
                    root.setDesktopTitle()
                    return
                }
                try {
                    var data = JSON.parse(out)
                    if (data && data.id) {
                        root.applyWindowInfo(data)
                    } else {
                        root.setDesktopTitle()
                    }
                } catch(e) {
                    root.setDesktopTitle()
                }
            }
        }
    }

    function refreshActiveWindow() {
        if (!focusedWinProc.running && root.isSupported) {
            focusedWinProc.running = true
        }
    }

    function _resolveAppName(appId, rawTitle) {
        if (appId && typeof appId === "string" && appId.trim() !== "") {
            var id = appId.trim()
            var entry = (typeof DesktopEntries !== "undefined" && DesktopEntries) ? (DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id)) : null
            if (entry && entry.name && entry.name.trim() !== "") {
                return entry.name.trim()
            }
            var clean = id.split(".").pop()
            if (clean && clean.length > 0) {
                return clean.charAt(0).toUpperCase() + clean.slice(1)
            }
            return id
        }
        if (rawTitle && typeof rawTitle === "string" && rawTitle.trim() !== "") {
            return rawTitle.charAt(0).toUpperCase() + rawTitle.slice(1)
        }
        return "Desktop"
    }

    function applyWindowInfo(win) {
        var appId = (win.app_id || "").toString().trim()
        var rawTitle = (win.title || "").toString().trim()
        if (appId !== "" || rawTitle !== "") {
            var windowName = root._resolveAppName(appId, rawTitle)
            root.activeTitle = windowName
            root.activeInitialTitle = windowName
            root.activeClass = appId
        } else {
            root.setDesktopTitle()
        }
        root.activeWindowChanged(root.activeTitle, root.activeInitialTitle, root.activeClass)
    }

    function setDesktopTitle() {
        root.activeTitle = "Desktop"
        root.activeInitialTitle = "Desktop"
        root.activeClass = ""
        root.activeWindowChanged("Desktop", "Desktop", "")
    }

    // ── Layout Management ─────────────────────────────────────────────────────
    readonly property var availableLayouts: ["scrolling"]
    readonly property string currentLayout: "scrolling"
    property string numWindows: "  "

    function setLayout(name) {}

    function cycleLayout(step = 1) {
        if (!root.isSupported) return
        actionProc.command = ["niri", "msg", "action", step > 0 ? "switch-preset-column-width" : "switch-preset-column-width-back"]
        actionProc.running = true
    }

    function toggleOverview() {
        if (!root.isSupported) return
        actionProc.command = ["niri", "msg", "action", "toggle-overview"]
        actionProc.running = true
    }

    function refreshLayout() {
        updateWindowCounts()
    }

    function updateWindowCounts() {
        var winList = root._rawWindows || []
        var currentWsRawId = root.focusedWorkspace ? root.focusedWorkspace.rawId : null
        var count = 0
        for (var i = 0; i < winList.length; i++) {
            if (currentWsRawId === null || winList[i].workspace_id === currentWsRawId) {
                count++
            }
        }
        root.numWindows = count > 0 ? count.toString() : "  "
    }

    // ── Event Stream Handling ─────────────────────────────────────────────────
    Process {
        id: eventStreamProc
        command: ["niri", "msg", "--json", "event-stream"]
        running: root.isSupported
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                root.parseEventLine(line)
            }
        }
        onExited: function() {
            if (root.isSupported) {
                reconnectTimer.restart()
            }
        }
    }

    Timer {
        id: reconnectTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (root.isSupported && !eventStreamProc.running) {
                eventStreamProc.running = true
            }
        }
    }

    function parseEventLine(line) {
        if (!line || line.trim() === "") return
        var evt
        try {
            evt = JSON.parse(line.trim())
        } catch(e) {
            return
        }
        if (!evt || typeof evt !== "object") return

        if (evt.WorkspacesChanged) {
            handleWorkspacesChanged(evt.WorkspacesChanged.workspaces)
        } else if (evt.WorkspaceActivated) {
            handleWorkspaceActivated(evt.WorkspaceActivated.id, evt.WorkspaceActivated.focused)
        } else if (evt.WindowsChanged) {
            handleWindowsChanged(evt.WindowsChanged.windows)
        } else if (evt.WindowOpenedOrChanged) {
            handleWindowOpenedOrChanged(evt.WindowOpenedOrChanged.window)
        } else if (evt.WindowClosed) {
            handleWindowClosed(evt.WindowClosed.id)
        } else if (evt.WindowFocusChanged) {
            handleWindowFocusChanged(evt.WindowFocusChanged.id)
        } else if (evt.WorkspaceActiveWindowChanged) {
            handleWorkspaceActiveWindowChanged(evt.WorkspaceActiveWindowChanged.workspace_id, evt.WorkspaceActiveWindowChanged.active_window_id)
        }
    }

    function handleWorkspacesChanged(rawWsList) {
        if (!Array.isArray(rawWsList)) return
        root._rawWorkspaces = rawWsList
        updateWorkspaceModels()
    }

    function updateWorkspaceModels() {
        var rawList = root._rawWorkspaces || []
        var mapped = []
        var activeId = 1
        var focusedWs = null

        for (var i = 0; i < rawList.length; i++) {
            var w = rawList[i]
            var displayId = (typeof w.idx === "number") ? w.idx : (i + 1)
            var isFocused = !!w.is_focused
            var isActive = !!w.is_active
            var isUrgent = !!w.is_urgent
            var nameStr = w.name || String(displayId)

            var hasWindows = (root._rawWindows || []).some(function(win) {
                return win.workspace_id === w.id
            })

            // Only track workspaces with windows or the currently focused/active workspace
            if (!hasWindows && !isFocused && !isActive) {
                continue
            }

            var wsObj = {
                id: displayId,
                rawId: w.id,
                idx: w.idx,
                name: nameStr,
                output: w.output || "",
                active: isActive,
                focused: isFocused,
                urgent: isUrgent
            }
            mapped.push(wsObj)

            if (isFocused || (isActive && !focusedWs)) {
                activeId = displayId
                focusedWs = wsObj
                if (w.output) root.focusedMonitorName = w.output
            }
        }

        mapped.sort(function(a, b) { return a.id - b.id })

        root.workspaces = mapped
        root.focusedWorkspaceId = activeId
        root.focusedWorkspace = focusedWs || (mapped.length > 0 ? mapped[0] : { id: 1, rawId: 1, name: "1" })
        root.workspaceChanged()
        updateWindowCounts()
    }

    function handleWorkspaceActivated(wsId, focused) {
        var rawList = root._rawWorkspaces || []
        for (var i = 0; i < rawList.length; i++) {
            if (rawList[i].id === wsId) {
                rawList[i].is_active = true
                if (focused) rawList[i].is_focused = true
            } else if (focused) {
                rawList[i].is_focused = false
            }
        }
        updateWorkspaceModels()
        root.dismissRequested()
    }

    function handleWindowsChanged(rawWinList) {
        if (!Array.isArray(rawWinList)) return
        root._rawWindows = rawWinList
        updateActiveWindowFromList()
        updateWindowCounts()
        updateWorkspaceModels()
    }

    function updateActiveWindowFromList() {
        var winList = root._rawWindows || []
        var focusedWin = null
        for (var i = 0; i < winList.length; i++) {
            if (winList[i].is_focused) {
                focusedWin = winList[i]
                break
            }
        }
        if (focusedWin) {
            applyWindowInfo(focusedWin)
        } else if (winList.length === 0 || !root._focusedWindowId) {
            setDesktopTitle()
        }
    }

    function handleWindowOpenedOrChanged(win) {
        if (!win) return
        var found = false
        var list = (root._rawWindows || []).slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === win.id) {
                list[i] = win
                found = true
                break
            }
        }
        if (!found) list.push(win)
        root._rawWindows = list

        if (win.is_focused) {
            applyWindowInfo(win)
        }
        updateWindowCounts()
        updateWorkspaceModels()
    }

    function handleWindowClosed(winId) {
        var list = (root._rawWindows || []).filter(function(w) { return w.id !== winId })
        root._rawWindows = list
        if (root._focusedWindowId === winId) {
            root._focusedWindowId = null
            updateActiveWindowFromList()
        }
        updateWindowCounts()
        updateWorkspaceModels()
    }

    function handleWindowFocusChanged(winId) {
        root._focusedWindowId = winId
        if (!winId) {
            setDesktopTitle()
            return
        }
        var winList = root._rawWindows || []
        var found = false
        for (var i = 0; i < winList.length; i++) {
            if (winList[i].id === winId) {
                winList[i].is_focused = true
                applyWindowInfo(winList[i])
                found = true
            } else {
                winList[i].is_focused = false
            }
        }
        if (!found) {
            refreshActiveWindow()
        }
    }

    function handleWorkspaceActiveWindowChanged(workspaceId, activeWindowId) {
        if (root.focusedWorkspace && root.focusedWorkspace.rawId === workspaceId) {
            handleWindowFocusChanged(activeWindowId)
        }
    }

    // ── Screen & Window Picking Commands ──────────────────────────────────────
    function pickWindowCommand() {
        return [
            "bash", "-c",
            "niri msg -j windows | python3 -c \"" +
            "import sys,json; ws=json.load(sys.stdin); " +
            "[print(f'{int(l[\\\"tile_pos_in_workspace_view\\\"][0])},{int(l[\\\"tile_pos_in_workspace_view\\\"][1])} {int(l.get(\\\"tile_size\\\", l.get(\\\"window_size\\\"))[0])}x{int(l.get(\\\"tile_size\\\", l.get(\\\"window_size\\\"))[1])} {w.get(\\\"app_id\\\", \\\"\\\")}') " +
            "for w in ws if w.get('layout') and w['layout'].get('tile_pos_in_workspace_view') and (w['layout'].get('tile_size') or w['layout'].get('window_size')) for l in [w['layout']]]\" | slurp"
        ]
    }

    function pickRegionCommand() {
        return [
            "bash", "-c",
            "niri msg -j outputs | python3 -c \"" +
            "import sys,json; data=json.load(sys.stdin); " +
            "[print(f'{int(log[\\\"x\\\"])},{int(log[\\\"y\\\"])} {int(log[\\\"width\\\"])}x{int(log[\\\"height\\\"])}') " +
            "for out in data.values() if isinstance(out, dict) and out.get('logical') for log in [out['logical']]]\" | slurp"
        ]
    }

    // ── Appearance & Commands ─────────────────────────────────────────────────
    property Process actionProc: Process {
        running: false
    }

    property Process themeWriteProc: Process {
        running: false
    }

    function setLayerBlur(namespace, enabled, alpha = 0.1) {}

    function setActiveBorderColor(color) {
        if (!color || !root.isSupported) return
        var hex = String(color).trim()
        if (hex.charAt(0) !== "#") hex = "#" + hex
        var themePath = Paths.configDir + "/BrainShell-niri-theme.kdl"
        var kdl = "layout {\n    border {\n        active-color \"" + hex + "\"\n    }\n    focus-ring {\n        active-color \"" + hex + "\"\n    }\n}\n"
        var escaped = kdl.replace(/\\/g, "\\\\").replace(/'/g, "'\\''")
        themeWriteProc.command = [
            "bash", "-c",
            "mkdir -p \"$(dirname '" + themePath + "')\" && " +
            "printf '%s' '" + escaped + "' > '" + themePath + "' && " +
            "(niri msg action load-config-file 2>/dev/null || true)"
        ]
        themeWriteProc.running = false
        themeWriteProc.running = true
    }

    function setKeybindCaptureSubmap(enabled) {}

    function focusUrgentOrLast() {
        if (!root.isSupported) return
        actionProc.command = ["niri", "msg", "action", "focus-window-previous"]
        actionProc.running = true
    }

    // ── Night Light ───────────────────────────────────────────────────────────
    property bool nightLightOn: false
    property Process nlCheckProc: Process {
        command: ["bash", "-c", "pgrep -x wlsunset || pgrep -x hyprsunset"]
        running: false
        onExited: function(code) {
            root.nightLightOn = (code === 0)
        }
    }
    property Process nlProc: Process {
        command: ["wlsunset", "-t", "5600"]
        running: false
    }
    property Process nlKillProc: Process {
        command: ["bash", "-c", "pkill wlsunset || pkill hyprsunset"]
        running: false
        onExited: function() {
            root.nightLightOn = false
        }
    }

    function checkNightLight() {
        if (!nlCheckProc.running) nlCheckProc.running = true
    }

    function setNightLight(enabled, temp = "5600") {
        if (enabled) {
            nlKillProc.running = false
            nlProc.command = ["wlsunset", "-t", String(temp)]
            nlProc.running = true
            root.nightLightOn = true
        } else {
            nlProc.running = false
            nlKillProc.running = false
            nlKillProc.running = true
            root.nightLightOn = false
        }
    }

    function toggleNightLight(temp = "5600") {
        setNightLight(!root.nightLightOn, temp)
    }

    // ── Display Power Cycling (DPMS) ──────────────────────────────────────────
    property Process dpmsProc: Process {
        running: false
    }

    function powerCycleDisplays() {
        if (!root.isSupported) return
        dpmsProc.command = ["bash", "-c", "niri msg action power-off-monitors && niri msg action power-on-monitors"]
        dpmsProc.running = true
    }

    // ── Window Gaps ───────────────────────────────────────────────────────────
    property int gapsIn: 5
    property int gapsOut: 10

    function setGaps(inVal, outVal) {
        if (inVal !== null && inVal !== undefined && inVal >= 0) root.gapsIn = inVal
        if (outVal !== null && outVal !== undefined && outVal >= 0) root.gapsOut = outVal
    }

    // ── Screen Shader ─────────────────────────────────────────────────────────
    readonly property string defaultShaderPaths: Paths.configDir + "/shaders"
    property string currentScreenShader: ""

    function checkScreenShader() {}
    function setScreenShader(name, shaderPaths) {}

    // ── Keybinds ──────────────────────────────────────────────────────────────
    property var rawKeybinds: []

    property Process keybindParseProc: Process {
        command: [
            "python3", "-c",
            "import re, os, json\n" +
            "cfg = os.path.expanduser('~/.config/niri/config.kdl')\n" +
            "binds = []\n" +
            "if os.path.exists(cfg):\n" +
            "    with open(cfg, 'r') as f: text = f.read()\n" +
            "    bm = re.search(r'binds\\s*\\{(.*?)\\n\\}', text, re.DOTALL)\n" +
            "    if bm:\n" +
            "        for line in bm.group(1).splitlines():\n" +
            "            line = line.strip()\n" +
            "            if not line or line.startswith('//') or line.startswith('/-'): continue\n" +
            "            m = re.match(r'^([A-Za-z0-9_+]+)(?:\\s+([^\\{]+))?\\s*\\{\\s*([^;]+);?\\s*\\}', line)\n" +
            "            if m:\n" +
            "                combo, opts, action = m.groups()\n" +
            "                parts = combo.split('+')\n" +
            "                key = parts[-1]\n" +
            "                mask = 0; mods = []\n" +
            "                for p in parts[:-1]:\n" +
            "                    pu = p.upper()\n" +
            "                    if pu in ('MOD', 'SUPER'): mask |= 64; mods.append('SUPER')\n" +
            "                    elif pu in ('CTRL', 'CONTROL'): mask |= 4; mods.append('CTRL')\n" +
            "                    elif pu in ('ALT',): mask |= 8; mods.append('ALT')\n" +
            "                    elif pu in ('SHIFT',): mask |= 1; mods.append('SHIFT')\n" +
            "                desc = ''\n" +
            "                if opts:\n" +
            "                    dm = re.search(r'hotkey-overlay-title=\"([^\"]+)\"', opts)\n" +
            "                    if dm: desc = dm.group(1)\n" +
            "                act = action.strip()\n" +
            "                ap = act.split(None, 1)\n" +
            "                disp = ap[0] if ap else ''\n" +
            "                arg = ap[1].strip('\"') if len(ap) > 1 else ''\n" +
            "                if not desc: desc = f'{disp}: {arg}' if arg else disp\n" +
            "                binds.append({'submap': '', 'mouse': 'Wheel' in key, 'modmask': mask, 'mods_str': ' + '.join(mods), 'key': key, 'dispatcher': disp, 'arg': arg, 'description': desc})\n" +
            "print(json.dumps(binds))\n"
        ]
        running: false
        stdout: StdioCollector {
            id: keybindCollector
            onStreamFinished: {
                try {
                    var data = JSON.parse(keybindCollector.text.trim())
                    if (Array.isArray(data)) {
                        root.rawKeybinds = data
                    }
                } catch(e) {}
            }
        }
    }

    function loadRawKeybinds() {
        if (!keybindParseProc.running && root.isSupported) {
            keybindParseProc.running = true
        }
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

    function _modsToMask(modsStr) {
        var mask = 0
        var parts = modsStr.toUpperCase().split("+")
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim()
            if      (p === "SUPER" || p === "MOD") mask |= 64
            else if (p === "SHIFT") mask |= 1
            else if (p === "CTRL" || p === "CONTROL")  mask |= 4
            else if (p === "ALT")   mask |= 8
        }
        return mask
    }

    function _effectiveMods(mods, key) {
        if ((!mods || mods === "") && _isModKey(key)) {
            return _modForModKey(key)
        }
        return mods || ""
    }

    function _normalizeKey(key) {
        if (!key) return ""
        var s = key.trim()
        var u = s.toUpperCase()
        if (u === "UNKNOWN") return ""
        if (u === "SUPER_L" || u === "SUPER") return "SUPER_L"
        if (u === "SUPER_R") return "SUPER_R"
        if (u === "ALT_L" || u === "ALT") return "Alt_L"
        if (u === "ALT_R" || u === "ALTGR") return "Alt_R"
        if (u === "CONTROL_L" || u === "CTRL_L" || u === "CTRL") return "Control_L"
        if (u === "CONTROL_R" || u === "CTRL_R") return "Control_R"
        if (u === "SHIFT_L" || u === "SHIFT") return "Shift_L"
        if (u === "SHIFT_R") return "Shift_R"
        return u
    }

    function wouldConflictCompositor(action, mods, key) {
        if (!key || key === "") return ""
        var mask = _modsToMask(_effectiveMods(mods, key))
        var k = _normalizeKey(key).toLowerCase()
        for (var i = 0; i < root.rawKeybinds.length; i++) {
            var b = root.rawKeybinds[i]
            if (b.submap !== "") continue
            if (b.mouse) continue
            if (b.arg && (b.arg.indexOf("qs ipc") >= 0 || b.arg.indexOf("quickshell ipc") >= 0 || b.arg.indexOf("brain-shell ipc") >= 0)) continue
            if (b.description && b.description.toLowerCase().indexOf("brain shell") >= 0) continue
            
            if (b.modmask === mask && (b.key || "").toLowerCase() === k) {
                if (b.description && b.description.trim() !== "") return b.description
                var desc = b.dispatcher || ""
                if (b.arg) desc += ": " + b.arg.substring(0, 36)
                return desc || "Niri bind"
            }
        }
        return ""
    }

    property Process keybindWriteProc: Process {
        running: false
    }

    function writeKeybindFiles(keybinds) {
        if (!root.isSupported) return
        var kdlPath = Paths.configDir + "/Brain_ShellKeybinds.kdl"
        var kdl = _genKdl(keybinds)
        var escaped = kdl.replace(/\\/g, "\\\\").replace(/'/g, "'\\''")
        keybindWriteProc.command = [
            "bash", "-c",
            "mkdir -p \"$(dirname '" + kdlPath + "')\" && " +
            "printf '%s' '" + escaped + "' > '" + kdlPath + "' && " +
            "(niri msg action load-config-file 2>/dev/null || true)"
        ]
        keybindWriteProc.running = false
        keybindWriteProc.running = true
    }

    function _groupedKeybinds(keybinds) {
        var groups = {}; var order = []
        var ks = Object.keys(keybinds || {})
        for (var i = 0; i < ks.length; i++) {
            var k = ks[i]; var b = keybinds[k]
            if (!b || b.mods === undefined || !b.key || b.key === "" || b.key.toUpperCase() === "UNKNOWN") continue
            var g = b.group || "Other"
            if (!groups[g]) { groups[g] = []; order.push(g) }
            var entry = { k: k, mods: b.mods, key: b.key, label: b.label }
            groups[g].push(entry)
        }
        return { groups: groups, order: order }
    }

    function _toNiriCombo(mods, key) {
        if (!key || key === "" || key.toUpperCase() === "UNKNOWN") return ""
        var modParts = []
        if (mods && mods !== "") {
            var parts = mods.toUpperCase().split("+")
            for (var i = 0; i < parts.length; i++) {
                var p = parts[i].trim()
                if (p === "SUPER") modParts.push("Mod")
                else if (p === "CTRL") modParts.push("Ctrl")
                else if (p === "ALT") modParts.push("Alt")
                else if (p === "SHIFT") modParts.push("Shift")
            }
        }
        var k = key.trim()
        var ku = k.toUpperCase()
        if (ku === "ESCAPE") k = "Escape"
        else if (ku === "PRINT") k = "Print"
        else if (ku === "RETURN" || ku === "ENTER") k = "Return"
        else if (ku === "SPACE") k = "Space"
        else if (ku === "TAB") k = "Tab"
        else if (ku === "BACKSPACE") k = "BackSpace"
        else if (ku === "DELETE") k = "Delete"
        else if (ku.startsWith("F") && ku.length <= 3 && !isNaN(ku.slice(1))) k = "F" + ku.slice(1)
        else if (k.length === 1) k = ku

        if (_isModKey(key) && modParts.length === 0) {
            var m = _modForModKey(key)
            if (m === "SUPER") return "Mod"
            if (m === "CTRL") return "Ctrl"
            if (m === "ALT") return "Alt"
            if (m === "SHIFT") return "Shift"
        }
        if (modParts.length === 0) return k
        return modParts.join("+") + "+" + k
    }

    function _genKdl(keybinds) {
        var sd = Paths.installDir.replace(/"/g, "\\\"")
        var data = _groupedKeybinds(keybinds)
        var lines = [
            "// ==============================================================================",
            "// Brain Shell Keybinds",
            "// Auto-generated by Quickshell. Do not edit manually.",
            "// ==============================================================================",
            "",
            "binds {"
        ]
        for (var gi = 0; gi < data.order.length; gi++) {
            var g = data.order[gi]
            lines.push("    // " + g)
            var entries = data.groups[g]
            for (var ei = 0; ei < entries.length; ei++) {
                var e = entries[ei]
                var kdlCombo = _toNiriCombo(e.mods, e.key)
                if (!kdlCombo) continue
                var title = "Brain Shell: " + (e.label || e.k).replace(/"/g, "\\\"")
                var execCmd = Paths.isNix
                    ? ("brain-shell ipc call " + e.k + " toggle")
                    : ("qs ipc -p " + sd + " call " + e.k + " toggle")
                lines.push("    " + kdlCombo + " hotkey-overlay-title=\"" + title + "\" { spawn-sh \"" + execCmd + "\"; }")
            }
            lines.push("")
        }
        lines.push("}")
        return lines.join("\n")
    }

    function reloadConfig() {
        if (!root.isSupported) return
        actionProc.command = ["niri", "msg", "action", "load-config-file"]
        actionProc.running = true
        root.configReloaded()
    }

    // ── Lock Screen ───────────────────────────────────────────────────────────
    function lockScreen() {
        actionProc.command = ["loginctl", "lock-session"]
        actionProc.running = true
    }

    // ── Initial State Queries ─────────────────────────────────────────────────
    property Process initWsProc: Process {
        command: ["niri", "msg", "-j", "workspaces"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim())
                    if (Array.isArray(data)) {
                        root.handleWorkspacesChanged(data)
                    }
                } catch(e) {}
            }
        }
    }

    property Process initWinProc: Process {
        command: ["niri", "msg", "-j", "windows"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim())
                    if (Array.isArray(data)) {
                        root.handleWindowsChanged(data)
                    }
                } catch(e) {}
            }
        }
    }

    Component.onCompleted: {
        if (!root.isSupported) return
        initWsProc.running = true
        initWinProc.running = true
        refreshActiveWindow()
        checkNightLight()
        loadRawKeybinds()
    }
}
