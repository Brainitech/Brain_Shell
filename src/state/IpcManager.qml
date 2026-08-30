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

    function _openDashboard(page) {
        Popups._ignoreDefaultTab = true
        
        if(Popups.anyOpen && !Popups.dashboardOpen){
            Popups.closeAll()
            SurfaceState.open("top", "dashboard")
            Popups.dashboardPage = page
            Popups.dashboardPinned = true
        } else if(Popups.dashboardOpen && Popups.dashboardPage != page) {
            Popups.dashboardPage = page
        } else {
            if (Popups.dashboardOpen) SurfaceState.close()
            else { Popups.closeAll(); SurfaceState.open("top", "dashboard") }
        }
        Popups._ignoreDefaultTab = false
    }

    property var dashboardHome: IpcHandler {
        target: "dashboard-home"
        function toggle() { _openDashboard("home") }
    }

    property var dashboardStats: IpcHandler {
        target: "dashboard-stats"
        function toggle() { _openDashboard("stats") }
    }

    property var dashboardKanban: IpcHandler {
        target: "dashboard-kanban"
        function toggle() { _openDashboard("kanban") }
    }

    property var dashboardLauncher: IpcHandler {
        target: "dashboard-launcher"
        function toggle() { _openDashboard("launcher") }
    }

    property var dashboardConfig: IpcHandler {
        target: "dashboard-config"
        function toggle() { _openDashboard("config") }
    }

    // ── Audio Toggles ────────────────────────────────────────

    function _openAudio(page) {
        Popups._ignoreDefaultTab = true
        if(Popups.anyOpen && !Popups.audioOpen) {
            Popups.closeAll()
            SurfaceState.open("right", "audio")
            Popups.audioPage = page
            Popups.audioPinned = true
        } else if (Popups.audioOpen && Popups.audioPage != page) {
            Popups.audioPage = page
        } else {
            var next = !Popups.audioOpen
            Popups.closeAll()
            SurfaceState.toggle("right", "audio")
            if (next) { Popups.audioPage = page; Popups.audioPinned = true; }
        }
        Popups._ignoreDefaultTab = false
    }

    property var audioOut: IpcHandler {
        target: "audioOut-toggle"
        function toggle() { _openAudio("output") }
    }

    property var audioMix: IpcHandler {
        target: "audioMix-toggle"
        function toggle() { _openAudio("mixer") }
    }

    property var audioIn: IpcHandler {
        target: "audioIn-toggle"
        function toggle() { _openAudio("input") }
    }

    // ── Network Toggles ──────────────────────────────────────

    property var wifiToggle: IpcHandler {
        target: "wifi-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.networkOpen) {
                Popups.closeAll()
                Popups.networkPage = "wifi"
                SurfaceState.open("right", "network")
                Popups.networkPinned = true
            } else if (Popups.networkOpen && Popups.networkPage != "wifi") {
                Popups.networkPage = "wifi"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                SurfaceState.toggle("right", "network")
                if (next) { Popups.networkPage = "wifi"; Popups.networkPinned = true; }
            }
        }
    }

    property var btToggle: IpcHandler {
        target: "bluetooth-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.networkOpen) {
                Popups.closeAll()
                Popups.networkPage = "bluetooth"
                SurfaceState.open("right", "network")
                Popups.networkPinned = true
            } else if (Popups.networkOpen && Popups.networkPage != "bluetooth") {
                Popups.networkPage = "bluetooth"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                SurfaceState.toggle("right", "network")
                if (next) { Popups.networkPage = "bluetooth"; Popups.networkPinned = true; }
            }
        }
    }

    property var vpnToggle: IpcHandler {
        target: "vpn-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.networkOpen) {
                Popups.closeAll()
                Popups.networkPage = "vpn"
                SurfaceState.open("right", "network")
                Popups.networkPinned = true
            } else if (Popups.networkOpen && Popups.networkPage != "vpn") {
                Popups.networkPage = "vpn"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                SurfaceState.toggle("right", "network")
                if (next) { Popups.networkPage = "vpn"; Popups.networkPinned = true; }
            }
        }
    }

    property var hotspotToggle: IpcHandler {
        target: "hotspot-toggle"
        function toggle() {
            if(Popups.anyOpen && !Popups.networkOpen) {
                Popups.closeAll()
                Popups.networkPage = "hotspot"
                SurfaceState.open("right", "network")
                Popups.networkPinned = true
            } else if (Popups.networkOpen && Popups.networkPage != "hotspot") {
                Popups.networkPage = "hotspot"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                SurfaceState.toggle("right", "network")
                if (next) { Popups.networkPage = "hotspot"; Popups.networkPinned = true; }
            }
        }
    }

    // ── Misc Toggles ─────────────────────────────────────────

    property var notification: IpcHandler {
        target: "notification-toggle"
        function toggle() {
            var next = !Popups.notificationsOpen
            Popups.closeAll()
            SurfaceState.toggle("right", "notifications")
            if (next) Popups.notificationsPinned = true
        }
    }

    property var clipboard: IpcHandler {
        target: "clipboard-toggle"
        function toggle() {
            var next = !Popups.clipboardOpen
            Popups.closeAll()
            SurfaceState.toggle("bottomRight", "clipboard")
            if (next) Popups.clipboardPinned = true
        }
    }

    property var wallpaper: IpcHandler {
        target: "wallpaper-toggle"
        function toggle() {
            var next = !Popups.wallpaperOpen
            Popups.closeAll()
            SurfaceState.toggle("bottomCenter", "wallpaper")
            if (next) Popups.wallpaperPinned = true
        }
    }

    property var archMenu: IpcHandler {
        target: "PowerMenu-toggle"
        function toggle() {
            var next = !Popups.archMenuOpen
            Popups.closeAll()
            SurfaceState.toggle("left", "archMenu")
            if (next) Popups.archMenuPinned = true
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

    signal focusToggleRequested()
}
