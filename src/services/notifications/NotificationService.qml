pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../../"

// ─────────────────────────────────────────────────────────────
// NotificationService — global singleton with bounded history,
// app-grouped model, and JSON persistence across restarts.
// ─────────────────────────────────────────────────────────────

NotificationServer {
    id: root

    bodyMarkupSupported:   true
    bodySupported:         true
    actionsSupported:      true
    keepOnReload:          true

    signal notificationAdded(var notification)

    property var list: []
    readonly property int count: list.length

    // Maximum notifications to keep in history (prevents unbounded growth)
    property int maxHistory: 50

    // ── Grouped model (Task 12) — app-grouped for Android/iOS-style display ──
    // [{ appName, appIcon, count, notifications: [...], mostRecent }]
    property var groupedModel: []

    function _rebuildGroupedModel() {
        var groups = {};
        var order = [];
        for (var i = 0; i < root.list.length; i++) {
            var n = root.list[i];
            var key = n.appName || "Unknown";
            if (!groups[key]) {
                groups[key] = { appName: key, appIcon: n.appIcon || "", notifications: [], mostRecent: n };
                order.push(key);
            }
            groups[key].notifications.push(n);
            groups[key].count = groups[key].notifications.length;
        }
        var result = [];
        for (var j = 0; j < order.length; j++) {
            result.push(groups[order[j]]);
        }
        root.groupedModel = result;
    }

    // ── Persistent history (Task 13) — JSON file ────────────────────────────
    readonly property string _historyPath:
        Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/notification_history.json"

    property var _historySaveProc: Process { command: []; running: false }

    function _saveHistory() {
        var data = [];
        for (var i = 0; i < root.list.length; i++) {
            var n = root.list[i];
            data.push({
                appName:    n.appName || "",
                appIcon:    n.appIcon || "",
                summary:    n.summary || "",
                body:       n.body || "",
                urgency:    n.urgency !== undefined ? n.urgency : 1,
                timestamp:  Date.now()
            });
        }
        var json = JSON.stringify(data);
        _historySaveProc.command = ["bash", "-c",
            "mkdir -p \"$(dirname '" + root._historyPath + "')\" && " +
            "printf '%s' '" + json.replace(/'/g, "'\\''") + "' > '" + root._historyPath + "'"];
        _historySaveProc.running = false;
        _historySaveProc.running = true;
    }

    property Timer _saveDebounce: Timer {
        interval: 2000
        repeat: false
        onTriggered: root._saveHistory()
    }

    // Load persisted history on startup (cosmetic only — these are NOT live notifications)
    property var _historyLoadProc: Process {
        command: ["bash", "-c",
            "[ -f '" + root._historyPath + "' ] && cat '" + root._historyPath + "' || echo '[]'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim());
                    // History is read-only display; real notifications come via DBus.
                    // We store the count for the bar indicator but don't hydrate live objects.
                    root._restoredHistoryCount = Array.isArray(data) ? data.length : 0;
                } catch (e) {
                    root._restoredHistoryCount = 0;
                }
            }
        }
    }

    property int _restoredHistoryCount: 0

    property bool _ready: false

    property Timer _startupTimer: Timer {
        interval: 500
        running: true
        onTriggered: {
            root._ready = true
            root._historyLoadProc.running = false
            root._historyLoadProc.running = true
        }
    }

    onNotification: function(n) {
        n.tracked = true

        if (root.list.includes(n)) return

        var newList = [n, ...root.list]
        // Enforce history limit
        if (newList.length > root.maxHistory) {
            var excess = newList.length - root.maxHistory
            for (var i = excess - 1; i >= 0; i--) {
                var old = newList[newList.length - 1]
                if (old && old.dismiss) old.dismiss()
            }
            newList = newList.slice(0, root.maxHistory)
        }
        root.list = newList
        root._rebuildGroupedModel()
        root._saveDebounce.restart()

        if (ShellState.dnd) return

        if (root._ready) {
            root.notificationAdded(n)
        }

        n.onClosed.connect(function() {
            root.list = root.list.filter(function(x) { return x !== n })
            root._rebuildGroupedModel()
            root._saveDebounce.restart()
        })
    }

    function dismissAll() {
        if (!root.list) return
        const list = [...root.list]
        for (const n of list) n.dismiss()
    }

    function clearHistory() {
        root.list = []
        root.groupedModel = []
        root._restoredHistoryCount = 0
    }
}
