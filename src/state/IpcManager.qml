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
            else { 
                Popups.closeAll()
                Popups.dashboardPage = page
                SurfaceState.open("top", "dashboard")
                Popups.dashboardPinned = true
            }
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
        if (Popups.audioOpen && Popups.audioPage !== page) {
            Popups.audioPage = page
        } else if (!Popups.audioOpen) {
            Popups.audioPage = page
            SurfaceState.open("rightCenter", "audio")
            Popups.audioPinned = true
        } else {
            SurfaceState.close()
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

    function _openNetwork(page) {
        if(Popups.anyOpen && !Popups.networkOpen) {
            Popups.closeAll()
            Popups.networkPage = page
            SurfaceState.open("right", "network")
            Popups.networkPinned = true
        } else if (Popups.networkOpen && Popups.networkPage != page) {
            Popups.networkPage = page
        } else {
            if (Popups.networkOpen) SurfaceState.close()
            else { 
                Popups.closeAll()
                Popups.networkPage = page
                SurfaceState.open("right", "network")
                Popups.networkPinned = true
            }
        }
    }

    property var wifiToggle: IpcHandler {
        target: "wifi-toggle"
        function toggle() { _openNetwork("wifi") }
    }

    property var btToggle: IpcHandler {
        target: "bluetooth-toggle"
        function toggle() { _openNetwork("bluetooth") }
    }

    property var vpnToggle: IpcHandler {
        target: "vpn-toggle"
        function toggle() { _openNetwork("vpn") }
    }

    property var hotspotToggle: IpcHandler {
        target: "hotspot-toggle"
        function toggle() { _openNetwork("hotspot") }
    }

    // ── Misc Toggles ─────────────────────────────────────────

    property var notification: IpcHandler {
        target: "notification-toggle"
        function toggle() {
            if (Popups.notificationsOpen) SurfaceState.close();
            else {
                Popups.closeAll();
                SurfaceState.open("right", "notifications");
                Popups.notificationsPinned = true;
            }
        }
    }

    property var clipboard: IpcHandler {
        target: "clipboard-toggle"
        function toggle() {
            if (Popups.clipboardOpen) SurfaceState.close();
            else {
                Popups.closeAll();
                SurfaceState.open("bottomRight", "clipboard");
                Popups.clipboardPinned = true;
            }
        }
    }

    property var wallpaper: IpcHandler {
        target: "wallpaper-toggle"
        function toggle() {
            if (Popups.wallpaperOpen) SurfaceState.close();
            else {
                Popups.closeAll();
                SurfaceState.open("bottomCenter", "wallpaper");
                Popups.wallpaperPinned = true;
            }
        }
    }

    property var archMenu: IpcHandler {
        target: "PowerMenu-toggle"
        function toggle() {
            if (Popups.archMenuOpen) SurfaceState.close();
            else {
                Popups.closeAll();
                SurfaceState.open("leftCenter", "archMenu");
                Popups.archMenuPinned = true;
            }
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
            ShellState.focusMode = !ShellState.focusMode
        }
    }

}
