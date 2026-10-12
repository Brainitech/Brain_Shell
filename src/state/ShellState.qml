/*
 * Brain Shell
 * Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import "../."

// Global shell state.
//
// WiFi / Bluetooth  — owned by QuickSettings (nmcli / bluetoothctl)
// Night Light       — owned by QuickSettings (WM.toggleNightLight)
// Caffeine          — owned by QuickSettings (systemd-inhibit)
// Hotspot           — owned by QuickSettings (nmcli hotspot)
// Airplane Mode     — owned by QuickSettings (rfkill)
// Focus Mode        — owned by QuickSettings; TopBar reacts to hide + zero gaps
// DND               — read by NotificationService to suppress incoming notifications
// VPN               — written by VPNTab; read by Network.qml for bar icon

QtObject {
    id: root

                
    // ── File System ───────────────────────────────────────────────────────────
    property string userDataDir: Paths.userDataDir

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
    }

    property var _batConn: Connections {
        target: UPower.displayDevice
        function onReadyChanged() {
            _checkBattery()
        }
    }
    
    // ── Keybind Interception / Compositor Submap Controller ───────────────────
    
    property Connections keybindListener: Connections {
        target: KeybindService 
        
        function onIsCapturingChanged() {
            WM.setKeybindCaptureSubmap(KeybindService.isCapturing)
        }
    }
    
    
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