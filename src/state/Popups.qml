pragma Singleton
import QtQuick

QtObject {
    // ── Per-popup open state ───────────────────────────────────────────────────
    property bool audioOpen:         false
    property bool networkOpen:       false
    property bool batteryOpen:       false
    property bool notificationsOpen: false
    property bool archMenuOpen:      false

    // ── Per-popup trigger hover state ─────────────────────────────────────────
    // Set true/false by the bar button's HoverHandler.
    // Popups that support hover-to-open read their own entry here.
    property bool audioTriggerHovered:         false
    property bool archMenuTriggerHovered:      false
    property bool networkTriggerHovered:       false
    property bool batteryTriggerHovered:       false
    property bool notificationsTriggerHovered: false

    // ── Universal popup behavior settings ─────────────────────────────────────
    property int  slideDuration:    260   // ms — slide in/out animation
    property int  hoverCloseDelay:  180   // ms — delay before closing on hover-leave

    // ── GPU warning (not a regular popup — excluded from closeAll) ────────────
    property bool   gfxWarningOpen: false
    property string pendingGfxMode: ""    // "Integrated" | "Hybrid"

    // ── Global state ──────────────────────────────────────────────────────────
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
