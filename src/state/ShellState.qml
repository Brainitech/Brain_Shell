pragma Singleton
import QtQuick

// Global shell state booleans.
//
// WiFi / Bluetooth  — managed by QuickSettings (polls nmcli/bluetoothctl directly)
// Night Light       — managed by QuickSettings (hyprsunset process)
// Caffeine          — managed by QuickSettings (systemd-inhibit process)
// Focus Mode        — managed by QuickSettings; TopBar reacts to hide bar + zero gaps

QtObject {
    property int topBarLWidth: 0
    property int topBarCWidth: 0
    property int topBarRWidth: 0
    
    
    property bool focusMode:    false
    property bool dnd:          false
    property bool screenRecord: false
}
