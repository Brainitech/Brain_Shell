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
                Popups.dashboardPinned = true
            } else if(Popups.dashboardOpen && Popups.dashboardPage != "home") {
                Popups.dashboardPage = "home"
            } else {
                var next = !Popups.dashboardOpen
                Popups.closeAll()
                Popups.dashboardOpen = next
                if (next) { Popups.dashboardPage = "home"; Popups.dashboardPinned = true; }
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
                if (next) { Popups.dashboardPage = "stats"; Popups.dashboardPinned = true; }
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
                if (next) { Popups.dashboardPage = "kanban"; Popups.dashboardPinned = true; }
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
                if (next) { Popups.dashboardPage = "launcher"; Popups.dashboardPinned = true; }
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
                Popups.dashboardPinned = true
            } else if(Popups.dashboardOpen && Popups.dashboardPage != "config") {
                Popups.dashboardPage = "config"
            } else {
                var next = !Popups.dashboardOpen
                Popups.closeAll()
                Popups.dashboardOpen = next
                if (next) { Popups.dashboardPage = "config"; Popups.dashboardPinned = true; }
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
                Popups.audioPinned = true
            } else if (Popups.audioOpen && Popups.audioPage != "output") {
                Popups.audioPage = "output"
            } else {
                var next = !Popups.audioOpen
                Popups.closeAll()
                Popups.audioOpen = next
                if (next) { Popups.audioPage = "output"; Popups.audioPinned = true; }
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
                Popups.audioPinned = true
            } else if (Popups.audioOpen && Popups.audioPage != "mixer") {
                Popups.audioPage = "mixer"
            } else {
                var next = !Popups.audioOpen
                Popups.closeAll()
                Popups.audioOpen = next
                if (next) { Popups.audioPage = "mixer"; Popups.audioPinned = true; }
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
                Popups.audioPinned = true
            } else if (Popups.audioOpen && Popups.audioPage != "input") {
                Popups.audioPage = "input"
            } else {
                var next = !Popups.audioOpen
                Popups.closeAll()
                Popups.audioOpen = next
                if (next) { Popups.audioPage = "input"; Popups.audioPinned = true; }
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
                Popups.networkPinned = true
            } else if (Popups.networkOpen && Popups.networkPage != "wifi") {
                Popups.networkPage = "wifi"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                Popups.networkOpen = next
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
                Popups.networkOpen = true
                Popups.networkPinned = true
            } else if (Popups.networkOpen && Popups.networkPage != "bluetooth") {
                Popups.networkPage = "bluetooth"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                Popups.networkOpen = next
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
                Popups.networkOpen = true
                Popups.networkPinned = true
            } else if (Popups.networkOpen && Popups.networkPage != "vpn") {
                Popups.networkPage = "vpn"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                Popups.networkOpen = next
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
                Popups.networkOpen = true
                Popups.networkPinned = true
            } else if (Popups.networkOpen && Popups.networkPage != "hotspot") {
                Popups.networkPage = "hotspot"
            } else {
                var next = !Popups.networkOpen
                Popups.closeAll()
                Popups.networkOpen = next
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
            Popups.notificationsOpen = next
            if (next) Popups.notificationsPinned = true
        }
    }

    property var clipboard: IpcHandler {
        target: "clipboard-toggle"
        function toggle() {
            var next = !Popups.clipboardOpen
            Popups.closeAll()
            Popups.clipboardOpen = next
            if (next) Popups.clipboardPinned = true
        }
    }

    property var wallpaper: IpcHandler {
        target: "wallpaper-toggle"
        function toggle() {
            var next = !Popups.wallpaperOpen
            Popups.closeAll()
            Popups.wallpaperOpen = next
            if (next) Popups.wallpaperPinned = true
        }
    }

    property var archMenu: IpcHandler {
        target: "PowerMenu-toggle"
        function toggle() {
            var next = !Popups.archMenuOpen
            Popups.closeAll()
            Popups.archMenuOpen = next
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
