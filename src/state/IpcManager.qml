pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// ─────────────────────────────────────────────────────────────
// IpcManager — centralized entry point for all external IPC signals.
//
// Moving handlers here ensures that on multi-monitor setups (where 
// TopBar/PopupLayer are duplicated) only ONE handler reacts to a signal.
// ─────────────────────────────────────────────────────────────

QtObject {
    id: root

    // ── Dashboard Toggles ────────────────────────────────────
    
    property var dashboardHome: IpcHandler {
        target: "dashboard-home"
        function toggle() {
            if(Popups.anyOpen && !Popups.dashboardOpen){
                Popups.closeAll()
                Popups.dashboardOpen = true
                Popups.dashboardPage = "home"
            } else if(Popups.dashboardOpen && Popups.dashboardPage != "home") {
                Popups.dashboardPage = "home"
            } else {
                var next = !Popups.dashboardOpen
                Popups.closeAll()
                Popups.dashboardOpen = next
                if (next) Popups.dashboardPage = "home"
            }
        }
    }

    property var dashboardStats: IpcHandler {
        target: "dashboard-stats"
        function toggle() {
            if(Popups.anyOpen && !Popups.dashboardOpen){
                Popups.closeAll()
                Popups.dashboardOpen = true
                Popups.dashboardPage = "stats"
            } else if(Popups.dashboardOpen && Popups.dashboardPage != "stats") {
                Popups.dashboardPage = "stats"
            } else {
                var next = !Popups.dashboardOpen
                Popups.closeAll()
                Popups.dashboardOpen = next
                if (next) Popups.dashboardPage = "stats"
            }
        }
    }

    property var dashboardKanban: IpcHandler {
        target: "dashboard-kanban"
        function toggle() {
            if(Popups.anyOpen && !Popups.dashboardOpen){
                Popups.closeAll()
                Popups.dashboardOpen = true
                Popups.dashboardPage = "kanban"
            } else if(Popups.dashboardOpen && Popups.dashboardPage != "kanban") {
                Popups.dashboardPage = "kanban"
            } else {
                var next = !Popups.dashboardOpen
                Popups.closeAll()
                Popups.dashboardOpen = next
                if (next) Popups.dashboardPage = "kanban"
            }
        }
    }

    property var dashboardLauncher: IpcHandler {
        target: "dashboard-launcher"
        function toggle() {
            if(Popups.anyOpen && !Popups.dashboardOpen){
                Popups.closeAll()
                Popups.dashboardOpen = true
                Popups.dashboardPage = "launcher"
            } else if(Popups.dashboardOpen && Popups.dashboardPage != "launcher") {
                Popups.dashboardPage = "launcher"
            } else {
                var next = !Popups.dashboardOpen
                Popups.closeAll()
                Popups.dashboardOpen = next
                if (next) Popups.dashboardPage = "launcher"
            }
        }
    }

    property var dashboardConfig: IpcHandler {
        target: "dashboard-config"
        function toggle() {
            if(Popups.anyOpen && !Popups.dashboardOpen){
                Popups.closeAll()
                Popups.dashboardOpen = true
                Popups.dashboardPage = "config"
            } else if(Popups.dashboardOpen && Popups.dashboardPage != "config") {
                Popups.dashboardPage = "config"
            } else {
                var next = !Popups.dashboardOpen
                Popups.closeAll()
                Popups.dashboardOpen = next
                if (next) Popups.dashboardPage = "config"
            }
        }
    }

    // ── Audio Toggles ────────────────────────────────────────

    property var audioOut: IpcHandler {
        target: "audioOut-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.audioOpen) {
                Popups.closeAll()
                Popups.audioPage = "output"
                Popups.audioOpen = true
            } else if (Popups.audioOpen && Popups.audioPage != "output") {
                Popups.audioPage = "output"
            } else {
                var next = !Popups.audioOpen
                Popups.closeAll()
                Popups.audioOpen = next
                if (next) Popups.audioPage = "output"
            }
        }
    }

    property var audioMix: IpcHandler {
        target: "audioMix-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.audioOpen) {
                Popups.closeAll()
                Popups.audioPage = "mixer"
                Popups.audioOpen = true
            } else if (Popups.audioOpen && Popups.audioPage != "mixer") {
                Popups.audioPage = "mixer"
            } else {
                var next = !Popups.audioOpen
                Popups.closeAll()
                Popups.audioOpen = next
                if (next) Popups.audioPage = "mixer"
            }
        }
    }

    property var audioIn: IpcHandler {
        target: "audioIn-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.audioOpen) {
                Popups.closeAll()
                Popups.audioPage = "input"
                Popups.audioOpen = true
            } else if (Popups.audioOpen && Popups.audioPage != "input") {
                Popups.audioPage = "input"
            } else {
                var next = !Popups.audioOpen
                Popups.closeAll()
                Popups.audioOpen = next
                if (next) Popups.audioPage = "input"
            }
        }
    }

    // ── Network Toggles ──────────────────────────────────────

    property var wifiToggle: IpcHandler {
        target: "wifi-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.networkOpen) {
                Popups.closeAll()
                Popups.networkPage = "wifi"
                Popups.networkOpen = true
            } else if (Popups.networkOpen && Popups.networkPage != "wifi") {
                Popups.networkPage = "wifi"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                Popups.networkOpen = next
                if (next) Popups.networkPage = "wifi"
            }
        }
    }

    property var btToggle: IpcHandler {
        target: "bluetooth-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.networkOpen) {
                Popups.closeAll()
                Popups.networkPage = "bluetooth"
                Popups.networkOpen = true
            } else if (Popups.networkOpen && Popups.networkPage != "bluetooth") {
                Popups.networkPage = "bluetooth"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                Popups.networkOpen = next
                if (next) Popups.networkPage = "bluetooth"
            }
        }
    }

    property var vpnToggle: IpcHandler {
        target: "vpn-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.networkOpen) {
                Popups.closeAll()
                Popups.networkPage = "vpn"
                Popups.networkOpen = true
            } else if (Popups.networkOpen && Popups.networkPage != "vpn") {
                Popups.networkPage = "vpn"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                Popups.networkOpen = next
                if (next) Popups.networkPage = "vpn"
            }
        }
    }

    property var hotspotToggle: IpcHandler {
        target: "hotspot-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.networkOpen) {
                Popups.closeAll()
                Popups.networkPage = "hotspot"
                Popups.networkOpen = true
            } else if (Popups.networkOpen && Popups.networkPage != "hotspot") {
                Popups.networkPage = "hotspot"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                Popups.networkOpen = next
                if (next) Popups.networkPage = "hotspot"
            }
        }
    }

    // ── Misc Toggles ─────────────────────────────────────────

    property var notification: IpcHandler {
        target: "notification-toggle"
        function toggle() {
            var next = !Popups.notificationsOpen
            Popups.closeAll()
            Popups.notificationsOpen = next
        }
    }

    property var clipboard: IpcHandler {
        target: "clipboard-toggle"
        function toggle() {
            var next = !Popups.clipboardOpen
            Popups.closeAll()
            Popups.clipboardOpen = next
        }
    }

    property var wallpaper: IpcHandler {
        target: "wallpaper-toggle"
        function toggle() {
            var next = !Popups.wallpaperOpen
            Popups.closeAll()
            Popups.wallpaperOpen = next
        }
    }

    property var archMenu: IpcHandler {
        target: "PowerMenu-toggle"
        function toggle() {
            var next = !Popups.archMenuOpen
            Popups.closeAll()
            Popups.archMenuOpen = next
        }
    }

    property var screenRec: IpcHandler {
        target: "screenrec-on"
        function toggle() {
            if (ScreenRecService.recording) {
                 ScreenRecService.stopRecording()
             } else if (ShellState.screenRecord) {
                 ScreenRecService.cancelSetup()
             } else {
                 Popups.closeAll()
                 ShellState.screenRecord = true
             }
        }
    }

    property var focusMode: IpcHandler {
        target: "focus-toggle"
        function toggle() {
            root.focusToggleRequested()
        }
    }

    // ── Screenshot Toggles ────────────────────────────────────

    property var screenshotScreen: IpcHandler {
        target: "screenshot-screen"
        function toggle() { ScreenshotTool.captureScreen() }
    }

    property var screenshotWindow: IpcHandler {
        target: "screenshot-window"
        function toggle() { ScreenshotTool.captureWindow() }
    }

    property var screenshotRegion: IpcHandler {
        target: "screenshot-region"
        function toggle() { ScreenshotTool.captureRegion() }
    }

    property var _colorPickerProc: Process {
        command: []
        running: false
    }

    property var _lockscreenProc: Process {
        command: []
        running: false
    }

    property var colorPicker: IpcHandler {
        target: "color-picker"
        function toggle() {
            _colorPickerProc.command = ["python3", Quickshell.shellDir + "/src/scripts/colorpicker.py"]
            _colorPickerProc.running = false
            _colorPickerProc.running = true
        }
    }

    // ── Unified IPC dispatcher (receives string commands from CLI pipe) ───────

    property var runCommand: IpcHandler {
        target: "brain-shell"
        // Use arguments object instead of typed parameter to avoid
        // Quickshell IPC QVariant serialization error
        function run() {
            var cmd = arguments.length > 0 ? String(arguments[0] || "") : ""
            _dispatchCommand(cmd)
        }
    }

    function _dispatchCommand(cmd) {
        if (!cmd || cmd === "") return

        switch (cmd) {
            // Dashboard
            case "dashboard":          Popups.dashboardOpen = !Popups.dashboardOpen; break
            case "dashboard-home":     _toggleDashboard("home");     break
            case "dashboard-stats":    _toggleDashboard("stats");    break
            case "dashboard-kanban":   _toggleDashboard("kanban");   break
            case "dashboard-launcher": _toggleDashboard("launcher"); break
            case "dashboard-config":   _toggleDashboard("config");   break

            // Launcher standalone
            case "launcher":
                if (Popups.anyOpen && !Popups.dashboardOpen) {
                    Popups.closeAll()
                    Popups.dashboardOpen = true
                    Popups.dashboardPage = "launcher"
                } else if (Popups.dashboardOpen && Popups.dashboardPage !== "launcher") {
                    Popups.dashboardPage = "launcher"
                } else {
                    var ln = !Popups.dashboardOpen
                    Popups.closeAll()
                    Popups.dashboardOpen = ln
                    if (ln) Popups.dashboardPage = "launcher"
                }
                break

            // Audio
            case "audio":
                var audioWasOpen = Popups.audioOpen
                Popups.closeAll()
                Popups.audioOpen = !audioWasOpen
                if (Popups.audioOpen) Popups.audioPage = "output"
                break

            // Network
            case "network":
                var netWasOpen = Popups.networkOpen
                Popups.closeAll()
                Popups.networkOpen = !netWasOpen
                if (Popups.networkOpen) Popups.networkPage = "wifi"
                break
            case "wifi-toggle":
                _toggleNetwork("wifi")
                break
            case "bt-toggle":
                _toggleNetwork("bluetooth")
                break
            case "vpn-toggle":
                _toggleNetwork("vpn")
                break
            case "hotspot-toggle":
                _toggleNetwork("hotspot")
                break

            // Notifications
            case "notifications":
                var notifWasOpen = Popups.notificationsOpen
                Popups.closeAll()
                Popups.notificationsOpen = !notifWasOpen
                break

            // Clipboard
            case "clipboard":
                var clipWasOpen = Popups.clipboardOpen
                Popups.closeAll()
                Popups.clipboardOpen = !clipWasOpen
                break

            // Wallpaper
            case "wallpaper":
                var wallWasOpen = Popups.wallpaperOpen
                Popups.closeAll()
                Popups.wallpaperOpen = !wallWasOpen
                break

            // Arch / Power menu
            case "arch-menu":
                var archWasOpen = Popups.archMenuOpen
                Popups.closeAll()
                Popups.archMenuOpen = !archWasOpen
                break

            // Quick settings
            case "quick-settings":
                var quickWasOpen = Popups.quickOpen
                Popups.closeAll()
                Popups.quickOpen = !quickWasOpen
                break

            // Overview (dashboard home)
            case "overview":
                _toggleDashboard("home")
                break

            // Lockscreen — hyprlock uses ~/.curr_wall_static.jpg maintained
            // by WallpaperService for all wallpaper types.
            case "lock":
            case "lockscreen":
                _lockscreenProc.command = ["bash", "-c", "hyprlock &"]
                _lockscreenProc.running = false
                _lockscreenProc.running = true
                break

            // Screenshot
            case "screenshot":
                ScreenshotTool.captureRegion()
                break
            case "screenshot-screen":
                ScreenshotTool.captureScreen()
                break
            case "screenshot-window":
                ScreenshotTool.captureWindow()
                break

            // Color picker
            case "color-picker":
                _colorPickerProc.command = ["python3", Quickshell.shellDir + "/src/scripts/colorpicker.py"]
                _colorPickerProc.running = false
                _colorPickerProc.running = true
                break

            // Focus mode
            case "focus":
                root.focusToggleRequested()
                break

            // Screen recording
            case "screen-record":
                if (ScreenRecService.recording) {
                    ScreenRecService.stopRecording()
                } else if (ShellState.screenRecord) {
                    ScreenRecService.cancelSetup()
                } else {
                    Popups.closeAll()
                    ShellState.screenRecord = true
                }
                break

            // Close all
            case "close-all":
                Popups.closeAll()
                break

            default:
                console.warn("IpcManager: unknown command:", cmd)
                break
        }
    }

    function _toggleDashboard(page) {
        if (Popups.anyOpen && !Popups.dashboardOpen) {
            Popups.closeAll()
            Popups.dashboardOpen = true
            Popups.dashboardPage = page
        } else if (Popups.dashboardOpen && Popups.dashboardPage !== page) {
            Popups.dashboardPage = page
        } else {
            var next = !Popups.dashboardOpen
            Popups.closeAll()
            Popups.dashboardOpen = next
            if (next) Popups.dashboardPage = page
        }
    }

    function _toggleNetwork(page) {
        if (Popups.anyOpen && !Popups.networkOpen) {
            Popups.closeAll()
            Popups.networkOpen = true
            Popups.networkPage = page
        } else if (Popups.networkOpen && Popups.networkPage !== page) {
            Popups.networkPage = page
        } else {
            var next = !Popups.networkOpen
            Popups.closeAll()
            Popups.networkOpen = next
            if (next) Popups.networkPage = page
        }
    }

    // ── Named pipe reader (zero-latency CLI → Shell IPC) ─────────────────────

    readonly property string _pipePath: "/tmp/brain_shell_ipc.pipe"

    property var _pipeSetupTimer: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: _ensurePipe()
    }

    function _ensurePipe() {
        // Create pipe if it doesn't exist (external process creates it before writing)
        var mkfifo = Qt.createQmlObject('import Quickshell.Io; Process { }', root)
        mkfifo.command = ["bash", "-c",
            "[ -p '" + _pipePath + "' ] || mkfifo '" + _pipePath + "' 2>/dev/null; true"]
        mkfifo.running = true
    }

    property var _pipeReader: Process {
        id: pipeReader
        // Persistent read loop — opens the FIFO ONCE, blocks on read(),
        // and outputs each line as it arrives. Zero process-spawn per keypress.
        // vs the old "while cat pipe; done" which forked cat on every event.
        command: ["bash", "-c",
            "until [ -p '" + root._pipePath + "' ]; do sleep 0.5; done; " +
            "while true; do while IFS= read -r line; do printf '%s\\n' \"$line\"; done < '" + root._pipePath + "'; done"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var cmd = line.trim()
                if (cmd !== "") root._dispatchCommand(cmd)
            }
        }
    }

    Component.onCompleted: {
        _ensurePipe()
        Qt.callLater(function() {
            pipeReader.running = true
        })
    }
    
    signal focusToggleRequested()
}
