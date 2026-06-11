pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io
import "../."

// Global shell state.
//
// WiFi / Bluetooth  — owned by QuickSettings (nmcli / bluetoothctl)
// Night Light       — owned by QuickSettings (hyprsunset)
// Caffeine          — owned by QuickSettings (systemd-inhibit)
// Hotspot           — owned by QuickSettings (nmcli hotspot)
// Airplane Mode     — owned by QuickSettings (rfkill)
// Focus Mode        — owned by QuickSettings; TopBar reacts to hide + zero gaps
// DND               — read by NotificationService to suppress incoming notifications
// VPN               — written by VPNTab; read by Network.qml for bar icon

QtObject {
    id: root

    property int topBarLWidth: 0
    property int topBarCWidth: 0
    property int topBarRWidth: 0
    
    
    property bool focusMode:    false
    property bool dnd:          false

    // ── Wallpaper advanced rendering (ported from NothingLess) ────────────────
    // All OFF by default → preserves Brain_Shell's original visual appearance.
    //   wallpaperTint           — tint live wallpaper toward the matugen palette
    //   wallpaperInterpolation  — motion interpolation (frame blending) for video
    //   interpolationMultiplier — 2..5, how many synthetic frames between real ones
    property bool wallpaperTint:           false
    property bool wallpaperInterpolation:  false
    property int  interpolationMultiplier: 2
    property bool screenRecord: false
    property bool hotspot:      false
    property bool airplane:     false

    // WiFi — false when radio is off OR hotspot is using the interface
    property bool wifiOn:       false

    // VPN — set by VPNTab, read by Network.qml bar indicator
    property bool   vpnActive:     false
    property bool   vpnConnecting: false
    property string vpnName:       ""

    // Bluetooth — written by BluetoothTab immediately on action, read by Network.qml
    // This avoids the 5s poll lag when a device disconnects or adapter toggles.
    property bool btPowered:   false   // adapter is on
    property bool btConnected: false   // at least one device connected

    // ── Keybind Interception / Hyprland Submap Controller ─────────────────────
    
    property Process submapProcess: Process {}

    property Connections keybindListener: Connections {
        target: KeybindService 
        
        function onIsCapturingChanged() {
            if (KeybindService.isCapturing) {
                // Enter passthrough mode (disables Hyprland binds)
                if (configProvider === "lua") {
                    submapProcess.command = ["hyprctl", "dispatch", "hl.dsp.submap('BrainShell_clean')"]
                } else {
                    submapProcess.command = ["hyprctl", "dispatch", "submap", "BrainShell_clean"]
                }
            } else {
                // Exit passthrough mode (re-enables Hyprland binds)
                if (configProvider === "lua") {
                    submapProcess.command = ["hyprctl", "dispatch", "hl.dsp.submap('reset')"]
                } else {
                    submapProcess.command = ["hyprctl", "dispatch", "submap", "reset"]
                }
            }
            
            submapProcess.running = true
        }
    }
    
    property string configProvider: "lua"
    
    // Watch the JSON file written by the installer
    property var _providerFile: FileView {
        id: providerFile
        path: Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/config_Provider.json"
        watchChanges: true
        
        onFileChanged: {
            reload()
        }
        
        onLoaded: {
            _parse(providerFile.text())
        }
    }
    
    function _parse(jsonString) {
        if (!jsonString || jsonString === "") return;
        try {
            let data = JSON.parse(jsonString)
            if (data.configProvider) {
                root.configProvider = data.configProvider
            }
        } catch (e) {
            console.error("Brain Shell: Failed to parse config_Provider.json")
        }
    }
}