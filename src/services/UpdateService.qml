pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// UpdateService — startup update checker (30s delay).
// Persistent PrefsService.autoUpdate preference stored in src/user_data/update_prefs.json.
QtObject {
    id: root

    // ── Persistent preference ──────────────────────────────────────────────
    

    // ── Live state (drives UpdatePopup) ───────────────────────────────────
    property bool   checking:        false
    property bool   updating:        false
    property bool   updateAvailable: false
    property bool   hasConflict:     false
    property bool   updateSuccess:   false
    
    property string updateVersion:   ""
    property string patchNotes:      ""
    property string lastError:       ""
    property int _pingAttempts:    0
    property int _pingMaxAttempts: 12
    
    property var _pingRetryTimer: Timer {
        interval: 5000
        repeat:   false
        onTriggered: root._pingCheck()
    }
    
    property var _pingProc: Process {
        command: ["ping", "-c", "1", "-W", "3", "1.1.1.1"]
        running: false
        onExited: function(code) {
            if (code === 0) {
                root._pingAttempts = 0
                root.check()
            } else {
                root._pingAttempts++
                // console.log("Ping attempt " + root._pingAttempts + " failed, retrying...")
                if (root._pingAttempts < root._pingMaxAttempts) {
                    root._pingRetryTimer.restart()
                } else {
                    root._pingAttempts = 0  // silent cancel
                    // console.log("Max ping attempts reached. Update check aborted.")
                }
            }
        }
    }
    
    function _startConnectivityCheck() {
        root._pingAttempts = 0
        root._pingCheck()
        // console.log("Started connectivity check for updates.")
    }
    
    function _pingCheck() {
        root._pingProc.running = false
        root._pingProc.running = true
    }

    // Popup is only shown when PrefsService.autoUpdate is enabled
    readonly property bool showPopup:
        PrefsService.autoUpdate && (
            updateAvailable ||
            updating ||
            hasConflict ||
            updateSuccess ||
            (lastError !== "" && !checking)
        )

    // ── Paths ──────────────────────────────────────────────────────────────
    // ── Startup: 30s delay ─────────────────────────────────────────────────
    property var _startTimer: Timer {
        interval: 30000
        repeat:   false
        running:  false
        onTriggered: root._startConnectivityCheck()
    }
    Component.onCompleted: if(PrefsService.autoUpdate) _startTimer.start()
    readonly property string _dir:        Quickshell.shellDir
    // ── Step 1: fetch origin/main ──────────────────────────────────────────
    property var _fetchProc: Process {
        command: ["git", "-C", root._dir, "fetch", "origin", "main", "--quiet"]
        running: false
        onExited: function(code) {
            if (code !== 0) {
                // console.log("UpdateService: git fetch failed with code " + code)
                root.checking  = false
                root.lastError = "Could not reach remote. Check your connection."
                return
            }
            // console.log("UpdateService: git fetch successful.")
            _countProc.running = false
            _countProc.running = true
        }
    }

    // ── Step 2: Check for new release tag ──────────────────────────────────────
    property var _countProc: Process {
        command: ["bash", "-c",
            "git -C '" + root._dir + "' fetch origin --tags --quiet; " +
            "LATEST_REMOTE=$(git -C '" + root._dir + "' describe --tags --abbrev=0 origin/main 2>/dev/null); " +
            "LATEST_LOCAL=$(git -C '" + root._dir + "' describe --tags --abbrev=0 HEAD 2>/dev/null); " +
            "if [ -n \"$LATEST_REMOTE\" ] && [ \"$LATEST_REMOTE\" != \"$LATEST_LOCAL\" ]; then " +
            "echo \"TAG:$LATEST_REMOTE\"; " +
            "git -C '" + root._dir + "' tag -l --format='%(contents)' \"$LATEST_REMOTE\"; " +
            "fi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim()
                if (out.startsWith("TAG:")) {
                    var nl = out.indexOf("\\n")
                    if (nl !== -1) {
                        root.updateVersion = out.substring(4, nl).trim()
                        root.patchNotes = out.substring(nl + 1).trim()
                    } else {
                        root.updateVersion = out.substring(4).trim()
                        root.patchNotes = "No patch notes provided."
                    }
                    root.checking = false
                    root.updateAvailable = true
                } else {
                    root.checking = false
                }
            }
        }
    }

    // ── Git pull ───────────────────────────────────────────────────────────
    property var _pullProc: Process {
        command: ["git", "-C", root._dir, "pull", "origin", "main"]
        running: false
        onExited: function(code) {
            root.updating = false
            if (code === 0) {
                // console.log("UpdateService: git pull successful.")
                root.updateAvailable = false
                root.hasConflict     = false
                root.lastError       = ""
                root.updateSuccess   = true
            } else {
                // console.log("UpdateService: git pull failed with code " + code + ". (Likely local conflict)")
                // fetch succeeded earlier, so failure = local changes conflict
                root.hasConflict = true
                root.lastError   = ""
            }
        }
    }

    // ── Stash local changes, then pull ────────────────────────────────────
    // stash pop is intentionally omitted — shell reloads after update anyway.
    // User can `git stash pop` manually if they want changes back.
    property var _stashPullProc: Process {
        command: ["bash", "-c",
            // stash with || true so an empty worktree doesn't abort the whole chain
            "git -C '" + root._dir + "' stash push -m 'brain-shell-pre-update' 2>/dev/null || true; " +
            "git -C '" + root._dir + "' pull origin main 2>&1"]
        running: false
        onExited: function(code) {
            root.updating = false
            if (code === 0) {
                // console.log("UpdateService: git stash + pull successful.")
                root.updateAvailable = false
                root.hasConflict     = false
                root.lastError       = ""
                root.updateSuccess   = true
            } else {
                // console.log("UpdateService: git stash + pull failed with code " + code)
                root.hasConflict = false
                root.lastError   = "Stash + pull failed. Try manually: git pull origin main"
            }
        }
    }

    // ── Public API ─────────────────────────────────────────────────────────

    function check() {
        // console.log("UpdateService: check() triggered")
        if (root.checking || root.updating) return
        root.checking        = true
        root.lastError       = ""
        root.updateAvailable = false
        root.updateSuccess   = false
        root.hasConflict     = false
        _fetchProc.running   = false
        _fetchProc.running   = true
    }

    function applyUpdate() {
        // console.log("UpdateService: applyUpdate() triggered")
        if (root.updating) return
        root.updating        = true
        root.hasConflict     = false
        root.lastError       = ""
        root.updateSuccess   = false
        _pullProc.running    = false
        _pullProc.running    = true
    }

    function stashAndUpdate() {
        // console.log("UpdateService: stashAndUpdate() triggered")
        if (root.updating) return
        root.updating            = true
        root.hasConflict         = false
        root.lastError           = ""
        root.updateSuccess       = false
        _stashPullProc.running   = false
        _stashPullProc.running   = true
    }

    function dismiss() {
        // console.log("UpdateService: dismiss() triggered")
        root.updateAvailable = false
        root.hasConflict     = false
        root.lastError       = ""
        root.updateSuccess   = false
    }

    function disableAutoUpdate() {
        // console.log("UpdateService: disableAutoUpdate() triggered")
        PrefsService.PrefsService.autoUpdate      = false
        root.updateAvailable = false
        root.hasConflict     = false
        root.lastError       = ""
        root.updateSuccess   = false
        root._startTimer.stop()
    }

}