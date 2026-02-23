pragma Singleton
import QtQuick

QtObject {
    property bool audioOpen:         false
    property bool networkOpen:       false
    property bool batteryOpen:       false
    property bool notificationsOpen: false
    property bool archMenuOpen:      false

    // Graphics mode warning dialog
    property bool   gfxWarningOpen:  false
    property string pendingGfxMode:  ""    // "Integrated" | "Hybrid"

    readonly property bool anyOpen: audioOpen || networkOpen || batteryOpen
                                    || notificationsOpen || archMenuOpen

    function closeAll() {
        audioOpen         = false
        networkOpen       = false
        batteryOpen       = false
        notificationsOpen = false
        archMenuOpen      = false
    }
}
