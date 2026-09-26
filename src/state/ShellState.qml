pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
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

                
    // ── File System ───────────────────────────────────────────────────────────
    property string userDataDir: Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data"

    property bool focusMode:    false
    property bool dnd:          false
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

    // ── Hardware Detection ──────────────────────────────────────────
    property bool hasBattery: false
    
    function _checkBattery() {
        if (UPower.displayDevice && UPower.displayDevice.ready) {
            hasBattery = UPower.displayDevice.isLaptopBattery
        }
    }
    
    Component.onCompleted: {
        _checkBattery()
        // Scan for Hyprland config provider (e.g. lua or conf)
        _configScanProc.command = ["bash", "-c", "hyprctl status | grep 'configProvider:' | awk '{print $2}'"]
        _configScanProc.running = true
    }
    
    property Process _configScanProc: Process {
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var provider = text.trim()
                if (provider !== "") {
                    root.configProvider = provider
                    // Store the result for external components or debugging if needed
                    var p = root.userDataDir + "/config_Provider.json"
                    var jsonStr = JSON.stringify({ configProvider: provider })
                    _saveConfigProc.command = ["bash", "-c", "mkdir -p \"$(dirname '" + p + "')\" && printf '%s' '" + jsonStr.replace(/'/g, "'\\''") + "' > '" + p + "'"]
                    _saveConfigProc.running = true
                }
                root.applyZeroGaps()
            }
        }
    }

    property Process zeroGapsProcess: Process { command: [] }
    property Timer zeroGapsTimer: Timer {
        interval: 10
        onTriggered: root.zeroGapsProcess.running = true
    }

    function applyZeroGaps() {
        zeroGapsProcess.running = false
        if (configProvider === "lua") {
            zeroGapsProcess.command = ["bash", "-c", "hyprctl eval \"hl.config({ general = { gaps_out = 0 } })\""]
        } else {
            zeroGapsProcess.command = ["hyprctl", "keyword", "general:gaps_out", "0"]
        }
        zeroGapsTimer.restart()
    }

    property Process _saveConfigProc: Process {
        command: []
        running: false
    }

    property var _batConn: Connections {
        target: UPower.displayDevice
        function onReadyChanged() {
            _checkBattery()
        }
    }
    
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
    
    property bool _bootFocusModeApplied: false
    property var _bootFocusConn: Connections {
        target: PrefsService
        function onLoaded() {
            if (!root._bootFocusModeApplied) {
                root.focusMode = PrefsService.bootFocusMode
                root._bootFocusModeApplied = true
            }
        }
    }
}