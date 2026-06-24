pragma Singleton
import QtQuick
import "../"

QtObject {
    property bool _ignoreDefaultTab: false

    // ── Per-popup open state ───────────────────────────────────────────────────
    property bool audioOpen:         false
    onAudioOpenChanged: {
        if (audioOpen && !_ignoreDefaultTab) {
            let opt = PrefsService.defaultAudioTab
            if (opt === "Input") audioPage = "input"
            else if (opt === "Mixers") audioPage = "mixer"
            else audioPage = "output"
        }
    }
    
    property bool networkOpen:       false
    property bool batteryOpen:       false
    property bool notificationsOpen: false
    property bool archMenuOpen:      false
    property bool dashboardOpen:     false
    onDashboardOpenChanged: {
        if (dashboardOpen && !_ignoreDefaultTab) {
            let opt = PrefsService.defaultDashboardTab
            if (opt === "System") dashboardPage = "stats"
            else if (opt === "Tasks") dashboardPage = "kanban"
            else if (opt === "Apps") dashboardPage = "launcher"
            else if (opt === "Config") dashboardPage = "config"
            else dashboardPage = "home"
        }
    }
    
    property bool wallpaperOpen:     false
    property bool notificationToastOpen:    false
    property bool quickOpen: false
    property bool clipboardOpen:     false

    // ── Per-popup pinned state (ignores hover-leave) ──────────────────────────
    property bool audioPinned:         false
    property bool networkPinned:       false
    property bool batteryPinned:       false
    property bool notificationsPinned: false
    property bool archMenuPinned:      false
    property bool dashboardPinned:     false
    property bool wallpaperPinned:     false
    property bool quickPinned:         false
    property bool clipboardPinned:     false

    // ── Dashboard — per-page state ───────────────────────────────────────────
    property int    dashboardPageWidth: 900
    property string dashboardPage:      "home"

    // ── Audio popup — per-page state ─────────────────────────────────────────
    property string audioPage: "output"

    // ── Network popup — per-page content (string key) ─────────────────────────
    property string networkPage: "wifi"

    // ── Per-popup trigger hover state ─────────────────────────────────────────
    property bool archMenuTriggerHovered:      false
    property bool audioTriggerHovered:         false
    property bool networkTriggerHovered:       false
    property bool batteryTriggerHovered:       false
    property bool notificationsTriggerHovered: false
    property bool wallpaperTriggerHovered:     false
    property bool quickTriggerHovered:         false
    property bool dashboardTriggerHovered:     false
    property bool clipboardTriggerHovered:     false

    // ── Hover allowance settings ──────────────────────────────────────────────
    property bool audioAllowHover:         false
    property bool networkAllowHover:       false
    property bool archMenuAllowHover:      false
    property bool wallpaperAllowHover:     false
    property bool clipboardAllowHover:     false
    property bool notificationsAllowHover: false
    property bool quickAllowHover:         true
    property bool dashboardAllowHover:     false

    // ── Universal popup behavior settings ─────────────────────────────────────
    property int  slideDuration:   Anim.transition
    property int  hoverCloseDelay: Anim.transition          // delay after hover leaves before closing
    property int  hoverOpenDelay:  150                     // delay before hover opens

    // ── Confirm dialog ────────────────────────────────────────────────────────
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
                                    || dashboardOpen || wallpaperOpen || quickOpen
                                    || clipboardOpen

    function closeAll() {
        audioOpen         = false
        networkOpen       = false
        batteryOpen       = false
        notificationsOpen = false
        archMenuOpen      = false
        dashboardOpen     = false
        wallpaperOpen     = false
        quickOpen         = false
        clipboardOpen     = false

        audioPinned         = false
        networkPinned       = false
        batteryPinned       = false
        notificationsPinned = false
        archMenuPinned      = false
        dashboardPinned     = false
        wallpaperPinned     = false
        quickPinned         = false
        clipboardPinned     = false
    }
}
