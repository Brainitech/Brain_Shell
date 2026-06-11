pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell

/*!
    UsageTracker — tracks app launch frequency for sorting + recent apps.

    Persists to ~/.config/Brain_Shell/src/user_data/usage.json
*/
QtObject {
    id: root

    property var _scores: ({})
    readonly property string _filePath: Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/usage.json"

    // ── Declarative processes (reusable, no Qt.createQmlObject overhead) ──

    property Process _loadProc: Process {
        command: ["bash", "-c",
            "[ -f '" + root._filePath + "' ] && cat '" + root._filePath + "' || echo '{}'"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    root._scores = JSON.parse(line.trim());
                } catch (e) {
                    root._scores = {};
                }
            }
        }
    }

    property Process _saveProc: Process {
        command: []
        running: false
    }

    property var _initTimer: Timer {
        interval: 0
        running: true
        onTriggered: {
            root._loadProc.running = false
            root._loadProc.running = true
        }
    }

    function _save() {
        var data = JSON.stringify(_scores);
        _saveProc.command = ["bash", "-c",
            "mkdir -p \"$(dirname '" + _filePath + "')\" && " +
            "printf '%s' '" + data.replace(/'/g, "'\\''") + "' > '" + _filePath + "'"];
        _saveProc.running = false;
        _saveProc.running = true;
    }

    function recordLaunch(appId) {
        var s = _scores[appId] || 0;
        _scores[appId] = s + 1;
        _save();
    }

    function getUsageScore(appId) {
        return _scores[appId] || 0;
    }

    function getRecentApps(limit) {
        limit = limit || 10;
        var entries = [];
        for (var id in _scores) {
            entries.push({ id: id, score: _scores[id] });
        }
        entries.sort((a, b) => b.score - a.score);
        return entries.slice(0, limit).map(e => e.id);
    }
}
