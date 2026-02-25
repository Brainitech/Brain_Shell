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
    property bool audioTriggerHovered:         false
    property bool networkTriggerHovered:       false
    property bool batteryTriggerHovered:       false
    property bool notificationsTriggerHovered: false

    // ── Universal popup behavior settings ─────────────────────────────────────
    property int  slideDuration:   260
    property int  hoverCloseDelay: 180

    // ── Confirm dialog ────────────────────────────────────────────────────────
    // Single reusable confirmation modal for any destructive action.
    // Call showConfirm() to open it — ConfirmDialog reads these props.
    //
    // confirmAction keys:
    //   "shutdown"    → systemctl poweroff
    //   "reboot"      → systemctl reboot
    //   "suspend"     → systemctl suspend
    //   "lock"        → loginctl lock-session
    //   "gfx-switch"  → supergfxctl -m confirmGfxMode, then hyprctl exit
    property bool   confirmOpen:    false
    property string confirmTitle:   ""
    property string confirmMessage: ""
    property string confirmLabel:   "Confirm"   // text on the confirm button
    property string confirmAction:  ""
    property string confirmGfxMode: ""          // only for "gfx-switch"
    property bool confirmRunning: false
    

    function showConfirm(title, message, label, action, gfxMode) {
        confirmTitle   = title
        confirmMessage = message
        confirmLabel   = label
        confirmAction  = action
        confirmGfxMode = gfxMode ?? ""
        confirmOpen    = true
    }

    function cancelConfirm() {
        confirmOpen    = false
        confirmAction  = ""
        confirmGfxMode = ""
    }

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
