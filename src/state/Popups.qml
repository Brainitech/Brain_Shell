pragma Singleton
import QtQuick
import "../"

QtObject {
    property bool _ignoreDefaultTab: false
    property var activeExpandedButton: null

    // ── Per-popup open state ───────────────────────────────────────────────────
    readonly property bool audioOpen: SurfaceState.activeContent === "audio"
    onAudioOpenChanged: {
        if (audioOpen && !_ignoreDefaultTab) {
            let opt = PrefsService.defaultAudioTab
            if (opt === "Input") audioPage = "input"
            else if (opt === "Mixers") audioPage = "mixer"
            else audioPage = "output"
        }
    }
    
    readonly property bool networkOpen: SurfaceState.activeContent === "network"
    readonly property bool batteryOpen: SurfaceState.activeContent === "battery"
    readonly property bool notificationsOpen: SurfaceState.activeContent === "notifications"
    readonly property bool archMenuOpen: SurfaceState.activeContent === "archMenu"
    readonly property bool dashboardOpen: SurfaceState.activeContent === "dashboard"
    onDashboardOpenChanged: {
        if (!dashboardOpen && activeExpandedButton) {
            activeExpandedButton.expanded = false
            activeExpandedButton = null
        }
        if (dashboardOpen && !_ignoreDefaultTab) {
            let opt = PrefsService.defaultDashboardTab
            if (opt === "System") dashboardPage = "stats"
            else if (opt === "Tasks") dashboardPage = "kanban"
            else if (opt === "Apps") dashboardPage = "launcher"
            else if (opt === "Config") dashboardPage = "config"
            else dashboardPage = "home"
        }
    }
    
    readonly property bool wallpaperOpen: SurfaceState.activeContent === "wallpaper"
    property bool notificationToastOpen: false
    readonly property bool quickOpen: SurfaceState.activeContent === "quick"
    readonly property bool clipboardOpen: SurfaceState.activeContent === "clipboard"
    property bool colorPickerActive: false
    
    // ── Per-popup pinned state (ignores hover-leave) ──────────────────────────
    property bool audioPinned:         false
    property bool networkPinned:       false
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
    property bool notificationsTriggerHovered: false
    property bool wallpaperTriggerHovered:     false
    property bool quickTriggerHovered:         false
    property bool dashboardTriggerHovered:     false
    property bool clipboardTriggerHovered:     false

    // ── Hover allowance settings ──────────────────────────────────────────────
    property bool audioAllowHover:         PrefsService.globalHoverMode && PrefsService.hoverAudio
    property bool archMenuAllowHover:      PrefsService.globalHoverMode && PrefsService.hoverArchMenu
    property bool wallpaperAllowHover:     PrefsService.globalHoverMode && PrefsService.hoverWallpaper
    property bool clipboardAllowHover:     PrefsService.globalHoverMode && PrefsService.hoverClipboard
    property bool notificationsAllowHover: PrefsService.globalHoverMode && PrefsService.hoverNotifications
    property bool quickAllowHover:         PrefsService.globalHoverMode && PrefsService.hoverQuick
    property bool dashboardAllowHover:     PrefsService.globalHoverMode && PrefsService.hoverDashboard

    // ── Universal popup behavior settings ─────────────────────────────────────
    property int  slideDuration:   Anim.transition
    property int  hoverCloseDelay: PrefsService.hoverCloseDelay          // delay after hover leaves before closing
    property int  hoverOpenDelay:  PrefsService.hoverOpenDelay           // delay before hover opens

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
        SurfaceState.close()
        audioPinned         = false
        networkPinned       = false
        notificationsPinned = false
        archMenuPinned      = false
        dashboardPinned     = false
        wallpaperPinned     = false
        quickPinned         = false
        clipboardPinned     = false
    }
}
