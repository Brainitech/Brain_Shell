pragma Singleton
import QtQuick

// Global shell state booleans.
// WiFi and Bluetooth are NOT here — QuickSettings polls them directly
// via nmcli/bluetoothctl and owns that state itself.

QtObject {
    property bool nightLight:   false   // managed by QuickSettings via hyprsunset
    property bool caffeine:     false
    property bool dnd:          false
    property bool gameMode:     false
    property bool screenRecord: false
}
