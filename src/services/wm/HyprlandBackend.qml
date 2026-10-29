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
import Quickshell.Hyprland
import "../../"

Item {
    id: root

    // ── Identity ──────────────────────────────────────────────────────────────
    readonly property string name: "Hyprland"
    readonly property bool isSupported: {
        var forced = Quickshell.env("BRAIN_SHELL_WM")
        if (typeof forced === "string" && forced.trim() !== "") {
            return forced.trim().toLowerCase() === "hyprland"
        }
        var hasNiri = typeof Quickshell.env("NIRI_SOCKET") === "string" && Quickshell.env("NIRI_SOCKET").trim() !== ""
        if (hasNiri) return false
        var hasSway = typeof Quickshell.env("SWAYSOCK") === "string" && Quickshell.env("SWAYSOCK").trim() !== ""
        if (hasSway) return false
        var hasHypr = typeof Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") === "string" && Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE").trim() !== ""
        if (hasHypr) return true
        var desk = (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toString().toLowerCase()
        return desk.indexOf("hyprland") !== -1
    }
    property string configProvider: "lua"

    property Process configScanProc: Process {
        command: ["bash", "-c", "hyprctl status 2>/dev/null | grep 'configProvider:' | awk '{print $2}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var provider = text.trim()
                if (provider !== "") {
                    root.configProvider = provider
                }
                root.setGaps(null, 0)
            }
        }
    }

    // ── Signals ───────────────────────────────────────────────────────────────
    signal activeWindowChanged(string title, string initialTitle, string windowClass)
    signal workspaceChanged()
    signal scratchpadChanged(bool active)
    signal dismissRequested()
    signal configReloaded()

    // ── Monitors & Displays ───────────────────────────────────────────────────
    readonly property string focusedMonitorName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : (Hyprland.monitors.length > 0 ? Hyprland.monitors[0].name : "")

    // ── Workspaces ────────────────────────────────────────────────────────────
    readonly property var workspaces: (Hyprland.workspaces && Hyprland.workspaces.values) ? Hyprland.workspaces.values : []
    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property int focusedWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    property bool isScratchpad: false

    function switchWorkspace(wsTarget, isSpecialToggle = false) {
        if (root.configProvider === "lua") {
            if (isSpecialToggle) {
                Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${wsTarget}")`)
            } else {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${wsTarget}" })`)
            }
        } else {
            if (isSpecialToggle) {
                Hyprland.dispatch(`togglespecialworkspace ${wsTarget}`)
            } else {
                Hyprland.dispatch(`workspace ${wsTarget}`)
            }
        }
    }

    function toggleScratchpad(name = "magic") {
        switchWorkspace(name, true)
    }

    function cycleWorkspace(direction = 1) {
        let occupied = Hyprland.workspaces.values.map(w => w.id).sort((a, b) => a - b)
        if (occupied.length === 0) return

        let currentId = focusedWorkspaceId || occupied[0]
        let idx = occupied.indexOf(currentId)
        if (idx === -1) idx = 0

        if (direction > 0) {
            idx = (idx + 1) % occupied.length
        } else {
            idx = (idx - 1 + occupied.length) % occupied.length
        }

        switchWorkspace(occupied[idx])
    }

    // ── Active Window Tracking ────────────────────────────────────────────────
    property string activeTitle: "Desktop"
    property string activeInitialTitle: "Desktop"
    property string activeClass: ""

    property Process titleProc: Process {
        command: ["hyprctl", "activewindow", "-j"]
        running: false
        stdout: StdioCollector {
            id: titleOut
        }
        onExited: function(exitCode, exitStatus) {
            var out = titleOut.text.trim()
            if (exitCode !== 0 || out === "" || out === "Invalid" || out === "{}") {
                root.activeTitle = "Desktop"
                root.activeInitialTitle = "Desktop"
                root.activeClass = ""
                root.activeWindowChanged("Desktop", "Desktop", "")
                return
            }

            try {
                var data = JSON.parse(out)
                var title = data.initialTitle || data.title || ""
                var winClass = data.class || ""

                if (title !== "") {
                    var finalTitle = title.charAt(0).toUpperCase() + title.slice(1)
                    root.activeTitle = finalTitle
                    root.activeInitialTitle = data.initialTitle || ""
                    root.activeClass = winClass
                } else {
                    root.activeTitle = "Desktop"
                    root.activeInitialTitle = "Desktop"
                    root.activeClass = ""
                }
                root.activeWindowChanged(root.activeTitle, root.activeInitialTitle, root.activeClass)
            } catch(e) {
                root.activeTitle = "Desktop"
                root.activeInitialTitle = "Desktop"
                root.activeClass = ""
                root.activeWindowChanged("Desktop", "Desktop", "")
            }
        }
    }

    function refreshActiveWindow() {
        if (!titleProc.running) {
            titleProc.running = true
        }
    }

    // ── Layout Management ─────────────────────────────────────────────────────
    readonly property var availableLayouts: ["dwindle", "master", "monocle", "scrolling"]
    property string currentLayout: ""
    property string numWindows: "  "

    property Process layoutQueryProc: Process {
        command: ["hyprctl", "-j", "activeworkspace"]
        running: false
        stdout: StdioCollector {
            id: layoutCollector
            onStreamFinished: {
                try {
                    const obj = JSON.parse(layoutCollector.text)
                    if (obj && obj.tiledLayout) {
                        root.currentLayout = obj.tiledLayout.toLowerCase()
                        root.numWindows = obj.windows > 0 ? obj.windows.toString() : "  "
                    }
                } catch(e) {}
            }
        }
    }

    function refreshLayout() {
        if (!layoutQueryProc.running) {
            layoutQueryProc.running = true
        }
    }

    property Process setLayoutProc: Process {
        running: false
    }

    function setLayout(newLayout) {
        if (root.configProvider === "lua") {
            setLayoutProc.command = ["hyprctl", "eval", `hl.config({ general = { layout = "${newLayout}" } })`]
        } else {
            setLayoutProc.command = ["hyprctl", "keyword", "general:layout", newLayout]
        }
        setLayoutProc.running = true
        root.currentLayout = newLayout
    }

    function cycleLayout(step = 1) {
        let idx = availableLayouts.indexOf(root.currentLayout)
        if (idx === -1) idx = 0
        idx = (idx + step + availableLayouts.length) % availableLayouts.length
        setLayout(availableLayouts[idx])
    }

    Timer {
        interval: 4000
        running: root.isSupported
        repeat: true
        onTriggered: root.refreshLayout()
    }

    // ── Raw Event Listener ────────────────────────────────────────────────────
    Connections {
        target: root.isSupported ? Hyprland : null

        function onRawEvent(event) {
            // Scratchpad events
            if (event.name === "activespecial" || event.name === "activespecialv2") {
                const wsName = event.data.split(',')[0]
                root.isScratchpad = (wsName !== "")
                root.scratchpadChanged(root.isScratchpad)
            } else if (event.name === "destroyworkspace") {
                root.isScratchpad = false
                root.scratchpadChanged(false)
            }

            // Window, Workspace, and Layout updates
            var titleTriggers = ["workspace", "activewindow", "activespecial", "destroyworkspace", "closewindow", "changefloatingmode", "openwindow"]
            if (titleTriggers.includes(event.name)) {
                root.refreshActiveWindow()
                root.refreshLayout()
                root.workspaceChanged()
            }

            // Dismiss requests (workspace, monitor switch, or window open)
            if (event.name === "workspace" || event.name === "focusedmon" || event.name === "activemonitor" || event.name === "activespecial" || event.name === "openwindow") {
                root.dismissRequested()
            }

            // Compositor config reload
            if (event.name === "configreloaded") {
                root.configReloaded()
            }
        }
    }

    // ── Screen & Window Picking Commands ──────────────────────────────────────
    function pickWindowCommand() {
        return [
            "bash", "-c",
            "hyprctl clients -j | python3 -c \"" +
            "import sys,json; ws=json.load(sys.stdin); " +
            "[print(str(w['at'][0])+','+str(w['at'][1])+' '+str(w['size'][0])+'x'+str(w['size'][1])) " +
            "for w in ws if w['mapped']]\" | slurp"
        ]
    }

    function pickRegionCommand() {
        return [
            "bash", "-c",
            "hyprctl monitors -j | python3 -c \"" +
            "import sys,json; ms=json.load(sys.stdin); " +
            "[print(str(m['x'])+','+str(m['y'])+' '+str(m['width'])+'x'+str(m['height'])) for m in ms]\" | slurp"
        ]
    }

    // ── Appearance & Commands ─────────────────────────────────────────────────
    property Process actionProc: Process {
        command: []
    }

    property Process blurProc: Process {
        command: []
        running: false
    }

    function setLayerBlur(namespace, enabled, alpha = 0.1) {
        if (!root.isSupported) return
        if (root.configProvider === "lua") {
            blurProc.command = enabled
                ? ["hyprctl", "eval", `hl.layer_rule({ match = { namespace = '${namespace}' }, blur = true, ignore_alpha = ${alpha} })`]
                : ["hyprctl", "eval", `hl.layer_rule({ match = { namespace = '${namespace}' }, blur = false })`]
        } else {
            blurProc.command = enabled
                ? ["bash", "-c", `hyprctl keyword layerrule 'unset, ${namespace}' && hyprctl keyword layerrule 'blur, ${namespace}' && hyprctl keyword layerrule 'ignorealpha ${alpha}, ${namespace}'`]
                : ["hyprctl", "keyword", "layerrule", `unset, ${namespace}`]
        }
        blurProc.running = true
    }

    function setActiveBorderColor(color) {
        let cleanCol = String(color).replace('#', '')
        if (root.configProvider === "lua") {
            actionProc.command = [
                "bash", "-c",
                "hyprctl eval 'hl.config({ general = { [\"col.active_border\"] = { colors = { \"rgb(" + cleanCol + ")\" } } } })'"
            ]
        } else {
            actionProc.command = [
                "bash", "-c",
                "hyprctl keyword general:col.active_border \"rgb(" + cleanCol + ")\""
            ]
        }
        actionProc.running = true
    }

    function setKeybindCaptureSubmap(enabled) {
        if (root.configProvider === "lua") {
            actionProc.command = ["hyprctl", "dispatch", enabled ? "hl.dsp.submap('BrainShell_clean')" : "hl.dsp.submap('reset')"]
        } else {
            actionProc.command = ["hyprctl", "dispatch", "submap", enabled ? "BrainShell_clean" : "reset"]
        }
        actionProc.running = true
    }

    function focusUrgentOrLast() {
        if (!root.isSupported) return
        if (root.configProvider === "lua") {
            actionProc.command = ["hyprctl", "dispatch", "hl.dsp.focusurgentorlast()"]
        } else {
            actionProc.command = ["hyprctl", "dispatch", "focusurgentorlast"]
        }
        actionProc.running = true
    }

    // ── Night Light (hyprsunset) ──────────────────────────────────────────────
    property bool nightLightOn: false
    property Process nlCheckProc: Process {
        command: ["bash", "-c", "pgrep -x hyprsunset"]
        running: false
        onExited: function(code) {
            root.nightLightOn = (code === 0)
        }
    }
    property Process nlProc: Process {
        command: ["hyprsunset", "-t", "5600"]
        running: false
    }
    property Process nlKillProc: Process {
        command: ["bash", "-c", "pkill hyprsunset"]
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
            nlProc.command = ["hyprsunset", "-t", String(temp)]
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
        if (root.configProvider === "lua") {
            dpmsProc.command = [
                "bash", "-c",
                "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })' && hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'"
            ]
        } else {
            dpmsProc.command = ["bash", "-c", "hyprctl dispatch dpms off && hyprctl dispatch dpms on"]
        }
        dpmsProc.running = true
    }

    // ── Window Gaps ───────────────────────────────────────────────────────────
    property int gapsIn: 5
    property int gapsOut: 10
    property Process gapsProc: Process {
        running: false
    }

    function setGaps(inVal, outVal) {
        if (!root.isSupported) return
        var cmds = []
        if (inVal !== null && inVal !== undefined && inVal >= 0) {
            root.gapsIn = inVal
            if (root.configProvider === "lua") {
                cmds.push(`hl.config({ general = { gaps_in = ${inVal} } })`)
            } else {
                cmds.push(`hyprctl keyword general:gaps_in ${inVal}`)
            }
        }
        if (outVal !== null && outVal !== undefined && outVal >= 0) {
            root.gapsOut = outVal
            if (root.configProvider === "lua") {
                cmds.push(`hl.config({ general = { gaps_out = ${outVal} } })`)
            } else {
                cmds.push(`hyprctl keyword general:gaps_out ${outVal}`)
            }
        }
        if (cmds.length === 0) return

        if (root.configProvider === "lua") {
            var evalStr = cmds.map(c => `hyprctl eval "${c}"`).join(" && ")
            gapsProc.command = ["bash", "-c", evalStr]
        } else {
            gapsProc.command = ["bash", "-c", cmds.join(" && ")]
        }
        gapsProc.running = true
    }

    // ── Screen Shader ─────────────────────────────────────────────────────────
    readonly property string defaultShaderPaths: Paths.configDir + "/shaders " + Paths.userDataDir + "/shaders ~/.config/hypr/shaders ~/.local/share/hypr/shaders /usr/share/hyprshade/shaders"
    property string currentScreenShader: ""
    property Process shaderCheckProc: Process {
        command: [
            "bash", "-c",
            "hyprctl getoption decoration:screen_shader -j 2>/dev/null | python3 -c \"" +
            "import sys,json,os; d=json.load(sys.stdin); " +
            "s=d.get('str','').strip(); print('' if s in ('','[[EMPTY]]') else os.path.splitext(os.path.basename(s))[0])\""
        ]
        running: false
        stdout: StdioCollector {
            id: shaderCollector
            onStreamFinished: {
                root.currentScreenShader = shaderCollector.text.trim()
            }
        }
    }

    function checkScreenShader() {
        if (!shaderCheckProc.running) shaderCheckProc.running = true
    }

    property Process shaderApplyProc: Process {
        running: false
        onExited: function() {
            root.checkScreenShader()
        }
    }

    function setScreenShader(name, shaderPaths) {
        var isLua = root.configProvider === "lua"
        var damageCmd = isLua 
            ? " && hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })' && hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'"
            : " && hyprctl dispatch dpms off && hyprctl dispatch dpms on"

        if (!name || name === "" || name === root.currentScreenShader) {
            var offCmd = isLua 
                ? "hyprctl eval \"hl.config({ decoration = { screen_shader = '' } })\""
                : "hyprctl keyword decoration:screen_shader '[[EMPTY]]'"
            shaderApplyProc.command = ["bash", "-c", offCmd + damageCmd]
            root.currentScreenShader = ""
        } else {
            var resolveCmd =
                "TARGET=$(find " + shaderPaths +
                " -maxdepth 1 -type f \\( -name '" + name + ".glsl' -o -name '" + name + ".frag' \\)" +
                " 2>/dev/null | head -n 1); "
            var onCmd = isLua
                ? "if [ -n \"$TARGET\" ]; then hyprctl eval \"hl.config({ decoration = { screen_shader = '$TARGET' } })\"" + damageCmd + "; fi"
                : "if [ -n \"$TARGET\" ]; then hyprctl keyword decoration:screen_shader \"$TARGET\"" + damageCmd + "; fi"
            shaderApplyProc.command = ["bash", "-c", resolveCmd + onCmd]
            root.currentScreenShader = name
        }
        shaderApplyProc.running = true
    }

    // ── Keybinds ──────────────────────────────────────────────────────────────
    property var rawKeybinds: []
    property Process rawBindsProc: Process {
        command: ["python3", Paths.installDir + "/src/scripts/hypr_binds.py"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.rawKeybinds = JSON.parse(text.trim()) }
                catch (e) { root.rawKeybinds = [] }
            }
        }
    }

    function loadRawKeybinds() {
        if (!root.isSupported) return
        rawBindsProc.running = false
        rawBindsProc.running = true
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
                if (b.dispatcher === "__lua") return "Lua Bind (No Description)"
                var desc = b.dispatcher || ""
                if (b.arg) desc += ": " + b.arg.substring(0, 36)
                return desc || "Hyprland bind"
            }
        }
        return ""
    }

    property Process reloadProc: Process {
        command: ["hyprctl", "reload"]
        running: false
    }

    function reloadConfig() {
        if (!root.isSupported) return
        if (root.configProvider === "lua") {
            reloadProc.command = ["bash", "-c", "hyprctl eval 'hl.reload()' 2>/dev/null || hyprctl reload"]
        } else {
            reloadProc.command = ["hyprctl", "reload"]
        }
        reloadProc.running = false
        reloadProc.running = true
    }

    property Process keybindWriteProc: Process {
        command: []
        running: false
    }

    function writeKeybindFiles(keybinds) {
        if (!root.isSupported) return
        var luaPath = Paths.configDir + "/Brain_ShellKeybinds.lua"
        var confPath = Paths.configDir + "/Brain_ShellKeybinds.conf"
        var lua = _genLua(keybinds)
        var conf = _genConf(keybinds)
        var le = lua.replace(/\\/g, "\\\\").replace(/'/g, "'\\''")
        var ce = conf.replace(/\\/g, "\\\\").replace(/'/g, "'\\''")
        
        keybindWriteProc.command = ["bash", "-c",
            "printf '%s' '" + le + "' > '" + luaPath + "' && " +
            "printf '%s' '" + ce + "' > '" + confPath + "'"]
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

    function _genLua(keybinds) {
        var sd = Paths.installDir.replace(/"/g, "\\\"")
        var data = _groupedKeybinds(keybinds)
        
        var lines = [
            "-- ==============================================================================",
            "-- Brain Shell Keybinds",
            "-- Auto-generated by Quickshell. Do not edit manually.",
            "-- ==============================================================================",
            ""
        ]

        if (!Paths.isNix) {
            lines.push("local shell = \"" + sd + "\"")
            lines.push("")
        }

        lines.push("-- ==============================================================================")
        lines.push("-- BrainShell Capture Submap (Disables all normal binds during recording)")
        lines.push("-- ==============================================================================")
        lines.push("hl.define_submap(\"BrainShell_clean\", function()")
        lines.push("    -- Emergency exit in case the shell crashes during capture")
        lines.push("    hl.bind(\"CTRL + ESCAPE\", function()")
        lines.push("        hl.dispatch(hl.dsp.exec_cmd(\"notify-send 'BrainShell' 'Emergency Exit: Keybinds re-enabled.'\"))")
        lines.push("        hl.dispatch(hl.dsp.submap(\"reset\"))")
        lines.push("    end, { description = \"Emergency return to global submap\" })")
        lines.push("end)")
        lines.push("")
        lines.push("-- ==============================================================================")
        lines.push("-- User Defined Bindings")
        lines.push("-- ==============================================================================")
        lines.push("")
        
        for (var gi = 0; gi < data.order.length; gi++) {
            var g = data.order[gi]
            lines.push("-- " + g)
            var entries = data.groups[g]
            for (var ei = 0; ei < entries.length; ei++) {
                var e = entries[ei]
                var isModOnly = (e.mods === "" && _isModKey(e.key))
                var luaBindStr = isModOnly
                    ? (_modForModKey(e.key) + " + " + e.key)
                    : ((e.mods !== "") ? (e.mods + " + " + e.key) : e.key)
                var descLabel = (e.label || e.k).replace(/"/g, "\\\"")
                var opts = isModOnly
                    ? "{ description = \"Brain Shell: " + descLabel + "\", release = true }"
                    : "{ description = \"Brain Shell: " + descLabel + "\" }"
                var execCmd = Paths.isNix
                    ? ("hl.dsp.exec_cmd(\"brain-shell ipc call " + e.k + " toggle\")")
                    : ("hl.dsp.exec_cmd(\"qs ipc -p \" .. shell .. \" call " + e.k + " toggle\")")
                lines.push("hl.bind(\"" + luaBindStr + "\", " + execCmd + ", " + opts + ")")
            }
            lines.push("")
        }
        return lines.join("\n")
    }

    function _genConf(keybinds) {
        var data = _groupedKeybinds(keybinds)
        
        var lines = [
            "# ==============================================================================",
            "# Brain Shell Keybinds",
            "# Auto-generated by Quickshell. Do not edit manually.",
            "# ==============================================================================",
            "",
            "# ==============================================================================",
            "# BrainShell Capture Submap (Disables all normal binds during recording)",
            "# ==============================================================================",
            "submap = BrainShell_clean",
            "bind = CTRL, ESCAPE, exec, notify-send 'BrainShell' 'Emergency Exit: Keybinds re-enabled.'",
            "bind = CTRL, ESCAPE, submap, reset",
            "submap = reset",
            "",
            "# ==============================================================================",
            "# User Defined Bindings",
            "# ==============================================================================",
            ""
        ]
        
        for (var gi = 0; gi < data.order.length; gi++) {
            var g = data.order[gi]
            lines.push("# " + g)
            var entries = data.groups[g]
            for (var ei = 0; ei < entries.length; ei++) {
                var e = entries[ei]
                var isModOnly = (e.mods === "" && _isModKey(e.key))
                var confMods = isModOnly
                    ? _modForModKey(e.key)
                    : e.mods.replace(/\s*\+\s*/g, " ")
                var bindDirective = isModOnly ? "bindr" : "bind"
                var cmd = Paths.isNix
                    ? ("brain-shell ipc call " + e.k + " toggle")
                    : ("qs ipc -p " + Paths.installDir + " call " + e.k + " toggle")
                lines.push(bindDirective + " = " + confMods + ", " + e.key + ", exec, " + cmd)
            }
            lines.push("")
        }
        return lines.join("\n")
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

    function _effectiveMods(mods, key) {
        if ((!mods || mods === "") && _isModKey(key)) {
            return _modForModKey(key)
        }
        return mods || ""
    }

    function _modsToMask(modsStr) {
        var mask = 0
        var parts = modsStr.toUpperCase().split("+")
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i].trim()
            if (p === "SUPER") mask |= 64
            else if (p === "SHIFT") mask |= 1
            else if (p === "CTRL") mask |= 4
            else if (p === "ALT") mask |= 8
        }
        return mask
    }

    // ── Lock Screen ───────────────────────────────────────────────────────────
    function lockScreen() {
        actionProc.command = ["loginctl", "lock-session"]
        actionProc.running = true
    }

    Component.onCompleted: {
        if (!root.isSupported) return
        configScanProc.running = true
        refreshActiveWindow()
        refreshLayout()
        checkNightLight()
        checkScreenShader()
    }
}
