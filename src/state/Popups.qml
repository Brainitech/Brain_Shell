pragma Singleton
import QtQuick

QtObject {
    // ── Per-popup open state ───────────────────────────────────────────────────
    property bool audioOpen:         false
    property bool networkOpen:       false
    property bool batteryOpen:       false
    property bool notificationsOpen: false
    property bool archMenuOpen:      false
    property bool dashboardOpen:     false
    property bool wallpaperOpen:     false
    property bool notificationToastOpen:    false

    // ── Dashboard — per-page width (px, content only, excluding fw padding) ───
    // Dashboard.qml writes this on every page change + on open.
    // TopBar.qml and Dashboard sizer both read it.
    property int dashboardPageWidth: 900

    // ── Per-popup trigger hover state ─────────────────────────────────────────
    property bool archMenuTriggerHovered: false
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
    //   "gfx-switch"  → envycontrol -m confirmGfxMode, then hyprctl exit
    property bool   confirmOpen:    false
    property string confirmTitle:   ""
    property string confirmMessage: ""
    property string confirmLabel:   "Confirm"
    property string confirmAction:  ""
    property string confirmGfxMode: ""
    property bool   confirmRunning: false

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
                                    || dashboardOpen || wallpaperOpen

    function closeAll() {
        audioOpen         = false
        networkOpen       = false
        batteryOpen       = false
        notificationsOpen = false
        archMenuOpen      = false
        dashboardOpen     = false
        wallpaperOpen     = false
    }
}
