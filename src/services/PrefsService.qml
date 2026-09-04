pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

QtObject {
    id: root

    signal loaded()

    property string customAvatarPath: ""
    property bool bootFocusMode: false
    property string defaultDashboardTab: "Home"
    property string defaultAudioTab: "Output"
    property bool use24HourTime: false

    // Sizing & Borders
    property bool barEnabled: true
    property int borderWidth: 6
    property int cornerRadius: 17
    property int notchRadius: 15

    // Popup Behavior
    property bool globalHoverMode: false
    property bool hoverDashboard: false
    property bool hoverNetwork: false
    property bool hoverAudio: false
    property bool hoverQuick: true
    property bool hoverArchMenu: false
    property bool hoverNotifications: false
    property bool hoverClipboard: false
    property bool hoverWallpaper: false
    
    property int hoverOpenDelay: 150
    property int hoverCloseDelay: 300

    property bool dynamicThemeOverride: false
    property bool darkMode: true
    property real bgOpacity: 1.0
    property bool bgBlur: false
    onBgBlurChanged: updateHyprlandBlur()
    Component.onCompleted: updateHyprlandBlur()

    // Custom Theme Override Groups
    property string overrideBg: "#1a282a"
    property string overrideBorder: "#ffffff"
    property string overrideActive: "#a6d0f7"
    property string overrideIconFont: "#2f8d97"
    property string overrideText: "#cdd6f4"
    property string overrideSubtext: "#94e2d5"
    property string overrideIcon: "#cdd6f4"

    property string _cfgBuf: ""
    
    property var _configFile: FileView {
        path: Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/shell_prefs.json"
        onLoaded: {
            root._parse(text())
        }
    }

    function _parse(raw) {
        if (!raw || raw.trim() === "") {
            root.updateHyprlandBlur()
            root.loaded()
            return
        }
        try {
            var o = JSON.parse(raw)
            if (o.customAvatarPath !== undefined) root.customAvatarPath = o.customAvatarPath
            if (o.bootFocusMode !== undefined) root.bootFocusMode = o.bootFocusMode
            if (o.defaultDashboardTab !== undefined) root.defaultDashboardTab = o.defaultDashboardTab
            if (o.defaultAudioTab !== undefined) root.defaultAudioTab = o.defaultAudioTab
            if (o.use24HourTime !== undefined) root.use24HourTime = o.use24HourTime

            if (o.barEnabled !== undefined) root.barEnabled = o.barEnabled
            if (o.borderWidth !== undefined) root.borderWidth = o.borderWidth
            if (o.cornerRadius !== undefined) root.cornerRadius = o.cornerRadius
            if (o.notchRadius !== undefined) root.notchRadius = o.notchRadius

            if (o.globalHoverMode !== undefined) root.globalHoverMode = o.globalHoverMode
            if (o.hoverDashboard !== undefined) root.hoverDashboard = o.hoverDashboard
            if (o.hoverNetwork !== undefined) root.hoverNetwork = o.hoverNetwork
            if (o.hoverAudio !== undefined) root.hoverAudio = o.hoverAudio
            if (o.hoverQuick !== undefined) root.hoverQuick = o.hoverQuick
            if (o.hoverArchMenu !== undefined) root.hoverArchMenu = o.hoverArchMenu
            if (o.hoverNotifications !== undefined) root.hoverNotifications = o.hoverNotifications
            if (o.hoverClipboard !== undefined) root.hoverClipboard = o.hoverClipboard
            if (o.hoverWallpaper !== undefined) root.hoverWallpaper = o.hoverWallpaper

            if (o.hoverOpenDelay !== undefined) root.hoverOpenDelay = o.hoverOpenDelay
            if (o.hoverCloseDelay !== undefined) root.hoverCloseDelay = o.hoverCloseDelay

            if (o.dynamicThemeOverride !== undefined) root.dynamicThemeOverride = o.dynamicThemeOverride
            if (o.overrideSecondary !== undefined) root.overrideSecondary = o.overrideSecondary
            if (o.darkMode !== undefined) root.darkMode = o.darkMode
            if (o.bgOpacity !== undefined) root.bgOpacity = o.bgOpacity
            if (o.bgBlur !== undefined) root.bgBlur = o.bgBlur
            if (o.overrideBg !== undefined) root.overrideBg = o.overrideBg
            if (o.overrideBorder !== undefined) root.overrideBorder = o.overrideBorder
            if (o.overrideActive !== undefined) root.overrideActive = o.overrideActive
            if (o.overrideIconFont !== undefined) root.overrideIconFont = o.overrideIconFont
            if (o.overrideText !== undefined) root.overrideText = o.overrideText
            if (o.overrideSubtext !== undefined) root.overrideSubtext = o.overrideSubtext
            if (o.overrideIcon !== undefined) root.overrideIcon = o.overrideIcon
        } catch(e) {}
        root.updateHyprlandBlur()
        root.loaded()
    }

    function saveConfig() {
        var path = Quickshell.env("HOME") + "/.config/Brain_Shell/src/user_data/shell_prefs.json"
        var data = JSON.stringify({
            customAvatarPath: root.customAvatarPath,
            bootFocusMode: root.bootFocusMode,
            defaultDashboardTab: root.defaultDashboardTab,
            defaultAudioTab: root.defaultAudioTab,
            use24HourTime: root.use24HourTime,
            barEnabled: root.barEnabled,
            borderWidth: root.borderWidth,
            cornerRadius: root.cornerRadius,
            notchRadius: root.notchRadius,
            globalHoverMode: root.globalHoverMode,
            hoverDashboard: root.hoverDashboard,
            hoverNetwork: root.hoverNetwork,
            hoverAudio: root.hoverAudio,
            hoverQuick: root.hoverQuick,
            hoverArchMenu: root.hoverArchMenu,
            hoverNotifications: root.hoverNotifications,
            hoverClipboard: root.hoverClipboard,
            hoverWallpaper: root.hoverWallpaper,
            hoverOpenDelay: root.hoverOpenDelay,
            hoverCloseDelay: root.hoverCloseDelay,
            dynamicThemeOverride: root.dynamicThemeOverride,
            overrideSecondary: root.overrideSecondary,
            darkMode: root.darkMode,
            bgOpacity: root.bgOpacity,
            bgBlur: root.bgBlur,
            overrideBg: root.overrideBg,
            overrideBorder: root.overrideBorder,
            overrideActive: root.overrideActive,
            overrideIconFont: root.overrideIconFont,
            overrideText: root.overrideText,
            overrideSubtext: root.overrideSubtext,
            overrideIcon: root.overrideIcon
        })
        _saveProc.command = ["bash", "-c", "mkdir -p \"$(dirname '" + path + "')\" && printf '%s' '" + data.replace(/'/g, "'\\''") + "' > '" + path + "'"]
        _saveProc.running = false
        _saveProc.running = true
    }

    function updateHyprlandBlur() {
        var isLua = ShellState.configProvider === "lua"
        var cmd = root.bgBlur
            ? (isLua ? "hyprctl eval \"hl.layer_rule({ match = { namespace = 'brain-shell-frame' }, blur = true, ignore_alpha = 0.1 })\""
                     : "hyprctl keyword layerrule 'unset, brain-shell-frame' && hyprctl keyword layerrule 'blur, brain-shell-frame' && hyprctl keyword layerrule 'ignorealpha 0.1, brain-shell-frame'")
            : (isLua ? "hyprctl eval \"hl.layer_rule({ match = { namespace = 'brain-shell-frame' }, blur = false })\""
                     : "hyprctl keyword layerrule 'unset, brain-shell-frame'")
        _blurProc.command = ["bash", "-c", "if [ -n \"$HYPRLAND_INSTANCE_SIGNATURE\" ]; then " + cmd + "; fi"]
        _blurProc.running = false
        _blurProc.running = true
    }

    property var _saveProc: Process { command: []; running: false }
    property var _blurProc: Process { command: []; running: false }
}
