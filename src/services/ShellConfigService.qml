pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell
import "."

/*!
    ShellConfigService — reactive JSON configuration for Brain_Shell.

    Persists to ~/.config/Brain_Shell/src/user_data/shell_config.json
*/
QtObject {
    id: root

    // ── Config values ─────────────────────────────────────────────────────────
    property real animationSpeed: 1.0
    property bool barEnabled: true
    property int dashboardWidth: 900
    property int dashboardHeight: 520
    property bool focusModeOnStartup: false
    property bool autoUpdateCheck: true

    readonly property string _filePath: Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/shell_config.json"

    // ── Load / Save ───────────────────────────────────────────────────────────
    property var _file: FileView {
        id: configFile
        path: root._filePath
        watchChanges: true
        onFileChanged: root._parse(text())
        onLoaded: root._parse(text())
    }

    property Process _ensureProc: Process {
        command: ["bash", "-c",
            "[ -f '" + root._filePath + "' ] || " +
            "(mkdir -p \"$(dirname '" + root._filePath + "')\" && " +
            "printf '%s' '{}' > '" + root._filePath + "')"]
        running: false
    }

    property Process _saveProc: Process {
        command: []
        running: false
    }

    Component.onCompleted: {
        _ensureProc.running = false
        _ensureProc.running = true
    }

    function _parse(raw) {
        if (!raw || raw.trim() === "") return
        try {
            var obj = JSON.parse(raw)

            if (typeof obj.animationSpeed === "number") root.animationSpeed = obj.animationSpeed
            if (typeof obj.barEnabled === "boolean") root.barEnabled = obj.barEnabled
            if (typeof obj.dashboardWidth === "number") root.dashboardWidth = obj.dashboardWidth
            if (typeof obj.dashboardHeight === "number") root.dashboardHeight = obj.dashboardHeight
            if (typeof obj.focusModeOnStartup === "boolean") root.focusModeOnStartup = obj.focusModeOnStartup
            if (typeof obj.autoUpdateCheck === "boolean") root.autoUpdateCheck = obj.autoUpdateCheck
        } catch (e) {
            console.warn("ShellConfigService: failed to parse config:", e)
        }
    }

    function save() {
        var data = JSON.stringify({
            animationSpeed: root.animationSpeed,
            barEnabled: root.barEnabled,
            dashboardWidth: root.dashboardWidth,
            dashboardHeight: root.dashboardHeight,
            focusModeOnStartup: root.focusModeOnStartup,
            autoUpdateCheck: root.autoUpdateCheck
        }, null, 2)
        _saveProc.command = ["bash", "-c",
            "mkdir -p \"$(dirname '" + _filePath + "')\" && " +
            "printf '%s' '" + data.replace(/'/g, "'\\''") + "' > '" + _filePath + "'"]
        _saveProc.running = false
        _saveProc.running = true
    }

    function resetToDefaults() {
        var defaults = { animationSpeed: 1.0, barEnabled: true, dashboardWidth: 900, dashboardHeight: 520, focusModeOnStartup: false, autoUpdateCheck: true };

        animationSpeed     = defaults.animationSpeed     || 1.0;
        barEnabled         = defaults.barEnabled         !== false;
        dashboardWidth     = defaults.dashboardWidth     || 900;
        dashboardHeight    = defaults.dashboardHeight    || 520;
        focusModeOnStartup = defaults.focusModeOnStartup || false;
        autoUpdateCheck    = defaults.autoUpdateCheck    !== false;
        save()
    }

    function clearAllData() {
        NotificationService.clearHistory()
        ClipboardService.wipeHistory()
        UsageTracker._scores = {}
        UsageTracker._save()
    }
}
