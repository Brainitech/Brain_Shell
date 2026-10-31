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

    NiriTheme {
        id: themeManager
        isSupported: root.isSupported
        gapsOut: root.gapsOut
    }

    function setLayerBlur(namespace, enabled, alpha = 0.1) {}

    function _writeNiriTheme() {
        themeManager.writeNiriTheme()
    }

    function setActiveBorderColor(color) {
        themeManager.setActiveBorderColor(color)
    }

    function setKeybindCaptureSubmap(enabled) {}

    function focusUrgentOrLast() {
        if (!root.isSupported) return
        actionProc.command = ["niri", "msg", "action", "focus-window-previous"]
        actionProc.running = true
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
    property bool _themeWritten: false

    function setGaps(inVal, outVal) {
        if (!root.isSupported) return
        var changed = false
        if (inVal !== null && inVal !== undefined && inVal >= 0 && inVal !== root.gapsIn) {
            root.gapsIn = inVal
        }
        if (outVal !== null && outVal !== undefined && outVal >= 0) {
            if (outVal !== root.gapsOut || !root._themeWritten) {
                root.gapsOut = outVal
                changed = true
            }
        }
        if (changed) {
            root._themeWritten = true
            _writeNiriTheme()
        }
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

    function wouldConflictCompositor(action, mods, key) {
        return KeyUtils.wouldConflict(root.rawKeybinds, action, mods, key, "Niri bind")
    }

    NiriKeybinds {
        id: keybindManager
        isSupported: root.isSupported
    }

    function writeKeybindFiles(keybinds) {
        keybindManager.writeKeybindFiles(keybinds)
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
        loadRawKeybinds()
    }
}
