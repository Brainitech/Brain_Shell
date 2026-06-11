pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell

/*!
    IdleService — monitors user idle time.

    Uses xprintidle ( Wayland-compatible via XWayland ) for accurate idle
    detection. Falls back to a simple timer-based estimate if unavailable.

    Signals:
        idleTimeout(seconds)  — emitted when idle crosses lockTimeout
        activityResumed()     — emitted when activity detected after idle
*/
QtObject {
    id: root

    // Milliseconds since last user activity
    property int idleTime: 0

    // Emitted when idleTime crosses thresholds
    signal idleTimeout(int seconds)
    signal activityResumed()

    // Configurable thresholds
    property int lockTimeout:    300000  // 5 min
    property int suspendTimeout: 600000  // 10 min

    property bool _locked: false
    property bool _suspended: false
    property bool _hasXprintidle: false

    // Check if xprintidle is available once at startup
    property Process _detectProc: Process {
        command: ["bash", "-c", "command -v xprintidle >/dev/null 2>&1 && echo yes || echo no"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                root._hasXprintidle = line.trim() === "yes"
                console.log("[IdleService] xprintidle:", root._hasXprintidle ? "available" : "unavailable")
                if (root._hasXprintidle) {
                    _pollTimer.interval = 2000
                } else {
                    // No xprintidle — increase interval to reduce CPU
                    _pollTimer.interval = 5000
                }
                _pollTimer.running = true
            }
        }
    }

    // Poll idle state
    property Timer _pollTimer: Timer {
        interval: 2000
        repeat: true
        running: false
        onTriggered: root._checkIdle()
    }

    property Process _idleProc: Process {
        command: ["xprintidle"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var ms = parseInt(line.trim())
                if (isNaN(ms)) return
                root.idleTime = ms

                if (root.idleTime < 1000) {
                    // Activity detected
                    if (root._locked || root._suspended) {
                        root._locked = false
                        root._suspended = false
                        root.activityResumed()
                    }
                }

                if (!root._locked && root.idleTime >= root.lockTimeout) {
                    root._locked = true
                    root.idleTimeout(Math.floor(root.idleTime / 1000))
                }
                if (!root._suspended && root.idleTime >= root.suspendTimeout) {
                    root._suspended = true
                    root.idleTimeout(Math.floor(root.idleTime / 1000))
                }
            }
        }
    }

    function _checkIdle() {
        if (root._hasXprintidle) {
            _idleProc.running = false
            _idleProc.running = true
        } else {
            // Fallback: without xprintidle, keep idleTime at 0 so video
            // wallpapers don't get stuck paused. hypridle handles actual
            // lock/suspend independently.
            if (root.idleTime !== 0) {
                root.idleTime = 0
                if (root._locked || root._suspended) {
                    root._locked = false
                    root._suspended = false
                    root.activityResumed()
                }
            }
        }
    }

    // Reset idle counter (called when activity is detected externally)
    function resetActivity() {
        root.idleTime = 0
        root._locked = false
        root._suspended = false
        root.activityResumed()
    }
}
