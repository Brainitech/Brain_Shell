pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell

/*!
    HyprlandService — centralized Hyprland compositor integration.

    Replaces all scattered hyprctl calls across the codebase with
    a single typed singleton. Provides:

    - Submap management (for keybind interception)
    - Gap read/write
    - Active border color
    - Shader management
    - Client/monitor listing (for screenshots, recording)
    - Config provider detection (lua vs .conf)
    - Workspace event socket (future: real-time events)

    Usage:
        HyprlandService.setGaps(5, 10)
        HyprlandService.setBorderColor("rgb(255,0,0)")
        HyprlandService.enterSubmap("BrainShell_clean")
*/
QtObject {
    id: root

    // ── Config provider ───────────────────────────────────────────────────────
    // "lua" (Hyprland >= 0.48) or "conf" (legacy)
    property string configProvider: "lua"

    property var _providerFile: FileView {
        id: providerFile
        path: Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/config_Provider.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: _parseProvider(text())
    }

    Component.onCompleted: _parseProvider(providerFile.text())

    function _parseProvider(raw) {
        if (!raw || raw.trim() === "") return
        try {
            var data = JSON.parse(raw)
            if (data.configProvider) root.configProvider = data.configProvider
        } catch (e) {
            console.warn("HyprlandService: failed to parse config_Provider.json")
        }
    }

    // ── Reusable process (avoids Qt.createQmlObject overhead for simple dispatches) ──
    property Process _hyprProc: Process {
    }
    // For JSON queries we use throwaway processes to avoid blocking the reusable one.
    function _runJson(args, callback) {
        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
        p.command = ["hyprctl"].concat(args)
        var collector = Qt.createQmlObject('import Quickshell.Io; StdioCollector {}', p)
        collector.onStreamFinished = function() {
            try {
                var data = JSON.parse(collector.text().trim())
                if (callback) callback(data)
            } catch (e) {
                console.warn("HyprlandService: JSON parse failed for", args.join(" "))
            }
        }
        p.stdout = collector
        p.running = true
    }

    // ── Submap ────────────────────────────────────────────────────────────────
    function enterSubmap(name) {
        if (configProvider === "lua")
            _hyprProc.command = ["hyprctl", "dispatch", "hl.dsp.submap('" + name + "')"]
        else
            _hyprProc.command = ["hyprctl", "dispatch", "submap", name]
        _hyprProc.running = false
        _hyprProc.running = true
    }

    function exitSubmap() {
        if (configProvider === "lua")
            _hyprProc.command = ["hyprctl", "dispatch", "hl.dsp.submap('reset')"]
        else
            _hyprProc.command = ["hyprctl", "dispatch", "submap", "reset"]
        _hyprProc.running = false
        _hyprProc.running = true
    }

    // ── Gaps ──────────────────────────────────────────────────────────────────
    function getGaps(callback) {
        // Returns { gapsIn: int, gapsOut: int }
        _runJson(["-j", "getoption", "general:gaps_in"], function(data) {
            var gapsIn = data.int || data.custom || "5"
            _runJson(["-j", "getoption", "general:gaps_out"], function(data2) {
                var gapsOut = data2.int || data2.custom || "10"
                if (callback) callback({ gapsIn: parseInt(gapsIn), gapsOut: parseInt(gapsOut) })
            })
        })
    }

    function setGaps(gapsIn, gapsOut) {
        if (configProvider === "lua") {
            _hyprProc.command = ["hyprctl", "keyword", "general:gaps_in", String(gapsIn),
                             "&&", "hyprctl", "keyword", "general:gaps_out", String(gapsOut)]
        } else {
            _hyprProc.command = ["bash", "-c",
                "hyprctl keyword general:gaps_in " + gapsIn +
                " && hyprctl keyword general:gaps_out " + gapsOut]
        }
        _hyprProc.running = false
        _hyprProc.running = true
    }

    // ── Border color ──────────────────────────────────────────────────────────
    function setBorderColor(rgbString) {
        if (configProvider === "lua") {
            _hyprProc.command = ["hyprctl", "eval",
                "'hl.config({ general = { [\"col.active_border\"] = { colors = { \"" + rgbString + "\" } } } })'"]
        } else {
            _hyprProc.command = ["hyprctl", "keyword", "general:col.active_border", "\"" + rgbString + "\""]
        }
        _hyprProc.running = false
        _hyprProc.running = true
    }

    // ── Shaders ───────────────────────────────────────────────────────────────
    function getCurrentShader(callback) {
        _runJson(["-j", "getoption", "decoration:screen_shader"], function(data) {
            if (callback) callback(data.str || data.custom || "")
        })
    }

    function setShader(shaderPath) {
        if (configProvider === "lua") {
            _hyprProc.command = ["hyprctl", "keyword", "decoration:screen_shader", shaderPath]
        } else {
            _hyprProc.command = ["hyprctl", "keyword", "decoration:screen_shader", shaderPath]
        }
        _hyprProc.running = false
        _hyprProc.running = true
    }

    // ── Client listing (for screenshots, recording) ──────────────────────────
    function getClients(callback) {
        _runJson(["-j", "clients"], callback)
    }

    function getMonitors(callback) {
        _runJson(["-j", "monitors"], callback)
    }

    // ── Workspace ─────────────────────────────────────────────────────────────
    function getActiveWorkspace(callback) {
        _runJson(["-j", "activeworkspace"], callback)
    }

    function dispatchWorkspace(ws) {
        _hyprProc.command = ["hyprctl", "dispatch", "workspace", String(ws)]
        _hyprProc.running = false
        _hyprProc.running = true
    }

    function moveToWorkspace(ws) {
        _hyprProc.command = ["hyprctl", "dispatch", "movetoworkspace", String(ws)]
        _hyprProc.running = false
        _hyprProc.running = true
    }

    // ── Dynamic keybind injection ─────────────────────────────────────────────
    // Foundation for Task 10: register/unregister keybinds at runtime
    function registerKeybind(keycombo, dispatcher, args) {
        var cmd = configProvider === "lua"
            ? "hyprctl keyword bind " + keycombo + "," + dispatcher + "," + args
            : "hyprctl keyword bind " + keycombo + "," + dispatcher + "," + args
        _hyprProc.command = ["bash", "-c", cmd]
        _hyprProc.running = false
        _hyprProc.running = true
    }

    function unregisterKeybind(keycombo) {
        var cmd = configProvider === "lua"
            ? "hyprctl keyword unbind " + keycombo
            : "hyprctl keyword unbind " + keycombo
        _hyprProc.command = ["bash", "-c", cmd]
        _hyprProc.running = false
        _hyprProc.running = true
    }

    // ── Raw dispatch (escape hatch for uncommon operations) ───────────────────
    function dispatch(action) {
        _hyprProc.command = ["hyprctl", "dispatch", action]
        _hyprProc.running = false
        _hyprProc.running = true
    }

    function rawJson(args, callback) {
        _runJson(args, callback)
    }
}
