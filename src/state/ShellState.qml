pragma Singleton
import QtQuick

// Global shell state.
//
// WiFi / Bluetooth  — owned by QuickSettings (nmcli / bluetoothctl)
// Night Light       — owned by QuickSettings (hyprsunset)
// Caffeine          — owned by QuickSettings (systemd-inhibit)
// Hotspot           — owned by QuickSettings (nmcli hotspot)
// Airplane Mode     — owned by QuickSettings (rfkill)
// Focus Mode        — owned by QuickSettings; TopBar reacts to hide + zero gaps
// DND               — read by NotificationService to suppress incoming notifications

QtObject {
    property int topBarLWidth: 0
    property int topBarCWidth: 0
    property int topBarRWidth: 0
    
    
    property bool focusMode:    false
    property bool dnd:          false
    property bool screenRecord: false
    property bool hotspot:      false
    property bool airplane:     false
}
