pragma Singleton
import QtQuick

// Central toggle state for all popups.
// Each button sets its property to true/false.
// Each PopupWindow binds its visible to its property.
QtObject {
    property bool audioOpen: false
    property bool networkOpen: false
    property bool batteryOpen: false
    property bool notificationsOpen: false
    property bool controlPanelOpen: false

    // Helper: close all popups at once (e.g. on workspace switch)
    function closeAll() {
        audioOpen        = false
        networkOpen      = false
        batteryOpen      = false
        notificationsOpen = false
        controlPanelOpen = false
    }
}
