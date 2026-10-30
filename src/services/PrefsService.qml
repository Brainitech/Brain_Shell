/*
 * Brain Shell
 * Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

QtObject {
    id: root

    signal loaded()
    property bool _loaded: false

    property string customAvatarPath: ""
    property bool bootFocusMode: false
    property bool focusModeHoverExpand: true
    property string defaultDashboardTab: "Home"
    property string defaultAudioTab: "Output"
    property bool use24HourTime: false
    property bool alwaysShowBatteryPercentage: false
    property bool alwaysShowVolumePercentage: false

    // Anim
    property string animStyle: "slide"
    property real animSpeed: 1.0
    property string animCurve: "smooth"

    // UpdateService
    property bool autoUpdate: true

    // ScreenRecService
    property string screenrecCaptureTarget: "region"
    property bool screenrecAudioMic: false
    property bool screenrecAudioSystem: false
    property int screenrecFramerate: 30
    property string screenrecBackend: "wf"   // wf | gsr | wlsr
    property string screenrecSaveDir: Quickshell.env("HOME") + "/Videos/screen_recordings"

    // Network (Hotspot)
    property string hotspotSsid: "BrainShell"
    property string hotspotPassword: "changeme1"

    // Sizing & Borders
    property string shellLayout: "border"
    readonly property bool isFloating: shellLayout === "floating"
    readonly property bool isBorderMode: shellLayout === "border"
    property int floatingGap: 8
    property int floatingBarHeight: 40

    property bool barEnabled: true
    property int borderWidth: 6
    property int cornerRadius: 17
    property int outerGaps: 10
    property string sliderStyle: "capsule"

    // Workspaces Customization
    property string wsMode: (WM.detectedCompositor === "Niri") ? "dynamic" : "static" // "static" | "dynamic" | "occupied"
    property int wsCount: 10 // 3 - 15 (for static mode)
    property string wsShape: "circle" // "circle" | "pill" | "rounded" | "square"
    property string wsSymbols: "none" // "none" | "numbers" | "kanji" | "roman" | "icons"
    property string wsSymbolStyle: "floating" // "floating" | "badges"
    property bool wsShowCapsule: true
    property bool wsInvertScroll: false

    // Popup Behavior
    property bool globalHoverMode: true
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

    property bool enableOsd: true
    property real osdDuration: 2.5
    property bool enableVisualiser: true

    property bool dynamicThemeOverride: false
    property bool darkMode: true
    property real bgOpacity: 1.0
    property bool bgBlur: false
    onBgBlurChanged: updateLayerBlur()
    Component.onCompleted: {
        updateLayerBlur()
        var p = ShellState.userDataDir + "/shell_prefs.json"
        _initProcPrefs.command = ["bash", "-c", "mkdir -p \"$(dirname \"" + p + "\")\" && touch \"" + p + "\"" ]
        _initProcPrefs.running = true
    }

    // Custom Theme Override Groups
    property string overrideBg: "#141311"
    property string overrideBorder: "#4a473c"
    property string overrideActive: "#f0e5bb"
    property string overrideIconFont: "#d3c9a1"
    property string overrideText: "#e6e2dd"
    property string overrideSubtext: "#ccc6b9"
    property string overrideIcon: "#e6e2dd"

    property string _cfgBuf: ""
    
    property var _configFile: FileView {
        path: ""
        onLoaded: {
            root._parse(text())
        }
    }

    function _parse(raw) {
        if (!raw || raw.trim() === "") {
            root.updateLayerBlur()
            root._loaded = true
                root.loaded()
            return
        }
        try {
            var o = JSON.parse(raw)
            if (o.customAvatarPath !== undefined) root.customAvatarPath = o.customAvatarPath
            if (o.bootFocusMode !== undefined) root.bootFocusMode = o.bootFocusMode
            if (o.focusModeHoverExpand !== undefined) root.focusModeHoverExpand = o.focusModeHoverExpand
            if (o.defaultDashboardTab !== undefined) root.defaultDashboardTab = o.defaultDashboardTab
            if (o.defaultAudioTab !== undefined) root.defaultAudioTab = o.defaultAudioTab
            if (o.use24HourTime !== undefined) root.use24HourTime = o.use24HourTime
            if (o.alwaysShowBatteryPercentage !== undefined) root.alwaysShowBatteryPercentage = o.alwaysShowBatteryPercentage
            if (o.alwaysShowVolumePercentage !== undefined) root.alwaysShowVolumePercentage = o.alwaysShowVolumePercentage

            if (o.animStyle !== undefined) root.animStyle = o.animStyle
            if (o.animSpeed !== undefined) root.animSpeed = o.animSpeed
            if (o.animCurve !== undefined) root.animCurve = o.animCurve
            if (o.autoUpdate !== undefined) root.autoUpdate = o.autoUpdate
            if (o.screenrecCaptureTarget !== undefined) root.screenrecCaptureTarget = o.screenrecCaptureTarget
            if (o.screenrecAudioMic !== undefined) root.screenrecAudioMic = o.screenrecAudioMic
            if (o.screenrecAudioSystem !== undefined) root.screenrecAudioSystem = o.screenrecAudioSystem
            if (o.screenrecFramerate !== undefined) root.screenrecFramerate = o.screenrecFramerate
            if (o.screenrecBackend !== undefined) root.screenrecBackend = o.screenrecBackend
            if (o.screenrecSaveDir !== undefined) root.screenrecSaveDir = o.screenrecSaveDir
            if (o.hotspotSsid !== undefined) root.hotspotSsid = o.hotspotSsid
            if (o.hotspotPassword !== undefined) root.hotspotPassword = o.hotspotPassword

            if (o.shellLayout !== undefined) root.shellLayout = o.shellLayout
            if (o.floatingGap !== undefined) root.floatingGap = Math.max(4, o.floatingGap)
            if (o.floatingBarHeight !== undefined) root.floatingBarHeight = o.floatingBarHeight

            if (o.barEnabled !== undefined) root.barEnabled = o.barEnabled
            if (o.borderWidth !== undefined) root.borderWidth = o.borderWidth
            if (o.cornerRadius !== undefined) root.cornerRadius = o.cornerRadius
            if (o.outerGaps !== undefined) root.outerGaps = o.outerGaps
            else root.outerGaps = 4
            if (o.sliderStyle !== undefined) {
                var s = o.sliderStyle
                if (s === "classic" || s === "rings" || s === "dots" || s === "dotted") root.sliderStyle = "capsule"
                else if (s === "modern") root.sliderStyle = "glow"
                else if (s === "concentric") root.sliderStyle = "outline"
                else if (s === "floating") root.sliderStyle = "ring"
                else if (s === "expanding") root.sliderStyle = "dynamic"
                else if (s === "futuristic") root.sliderStyle = "segmented"
                else root.sliderStyle = s
            }

            if (o.wsMode !== undefined) root.wsMode = (WM.detectedCompositor === "Niri") ? "dynamic" : o.wsMode
            if (o.wsCount !== undefined) root.wsCount = o.wsCount
            if (o.wsShape !== undefined) root.wsShape = o.wsShape
            if (o.wsSymbols !== undefined) root.wsSymbols = o.wsSymbols
            if (o.wsSymbolStyle !== undefined) root.wsSymbolStyle = (o.wsSymbolStyle === "badges") ? "badges" : "floating"
            if (o.wsShowCapsule !== undefined) root.wsShowCapsule = o.wsShowCapsule
            if (o.wsInvertScroll !== undefined) root.wsInvertScroll = o.wsInvertScroll

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

            if (o.enableOsd !== undefined) root.enableOsd = o.enableOsd
            if (o.osdDuration !== undefined) root.osdDuration = o.osdDuration
            if (o.enableVisualiser !== undefined) root.enableVisualiser = o.enableVisualiser

            if (o.dynamicThemeOverride !== undefined) root.dynamicThemeOverride = o.dynamicThemeOverride
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
        root.updateLayerBlur()
        if (!ShellState.focusMode) {
            WM.setGaps(WM.gapsIn, root.outerGaps)
        }
        root._loaded = true
        root.loaded()
    }

        onCustomAvatarPathChanged: if (_loaded) saveConfig()
    onBootFocusModeChanged: if (_loaded) saveConfig()
    onFocusModeHoverExpandChanged: if (_loaded) saveConfig()
    onDefaultDashboardTabChanged: if (_loaded) saveConfig()
    onDefaultAudioTabChanged: if (_loaded) saveConfig()
    onUse24HourTimeChanged: if (_loaded) saveConfig()
    onAlwaysShowBatteryPercentageChanged: if (_loaded) saveConfig()
    onAlwaysShowVolumePercentageChanged: if (_loaded) saveConfig()
    onAnimStyleChanged: if (_loaded) saveConfig()
    onAnimSpeedChanged: if (_loaded) saveConfig()
    onAnimCurveChanged: if (_loaded) saveConfig()
    onAutoUpdateChanged: if (_loaded) saveConfig()
    onScreenrecCaptureTargetChanged: if (_loaded) saveConfig()
    onScreenrecAudioMicChanged: if (_loaded) saveConfig()
    onScreenrecAudioSystemChanged: if (_loaded) saveConfig()
    onScreenrecFramerateChanged: if (_loaded) saveConfig()
    onScreenrecBackendChanged: if (_loaded) saveConfig()
    onScreenrecSaveDirChanged: if (_loaded) saveConfig()
    onHotspotSsidChanged: if (_loaded) saveConfig()
    onHotspotPasswordChanged: if (_loaded) saveConfig()
    onShellLayoutChanged: if (_loaded) saveConfig()
    onFloatingGapChanged: { if (floatingGap < 4) floatingGap = 4; if (_loaded) saveConfig() }
    onFloatingBarHeightChanged: if (_loaded) saveConfig()
    onBarEnabledChanged: if (_loaded) saveConfig()
    onBorderWidthChanged: if (_loaded) saveConfig()
    onIsFloatingChanged: if (_loaded) saveConfig()
    onOuterGapsChanged: {
        if (_loaded) {
            saveConfig()
            if (!ShellState.focusMode) {
                WM.setGaps(WM.gapsIn, outerGaps)
            }
        }
    }
    onCornerRadiusChanged: if (_loaded) saveConfig()
    onSliderStyleChanged: if (_loaded) saveConfig()
    onWsModeChanged: if (_loaded) saveConfig()
    onWsCountChanged: if (_loaded) saveConfig()
    onWsShapeChanged: if (_loaded) saveConfig()
    onWsSymbolsChanged: if (_loaded) saveConfig()
    onWsSymbolStyleChanged: if (_loaded) saveConfig()
    onWsShowCapsuleChanged: if (_loaded) saveConfig()
    onWsInvertScrollChanged: if (_loaded) saveConfig()
    onGlobalHoverModeChanged: if (_loaded) saveConfig()
    onHoverDashboardChanged: if (_loaded) saveConfig()
    onHoverNetworkChanged: if (_loaded) saveConfig()
    onHoverAudioChanged: if (_loaded) saveConfig()
    onHoverQuickChanged: if (_loaded) saveConfig()
    onHoverArchMenuChanged: if (_loaded) saveConfig()
    onHoverNotificationsChanged: if (_loaded) saveConfig()
    onHoverClipboardChanged: if (_loaded) saveConfig()
    onHoverWallpaperChanged: if (_loaded) saveConfig()
    onHoverOpenDelayChanged: if (_loaded) saveConfig()
    onHoverCloseDelayChanged: if (_loaded) saveConfig()
    onEnableOsdChanged: if (_loaded) saveConfig()
    onOsdDurationChanged: if (_loaded) saveConfig()
    onEnableVisualiserChanged: if (_loaded) saveConfig()
    onDynamicThemeOverrideChanged: if (_loaded) saveConfig()
    onDarkModeChanged: if (_loaded) saveConfig()
    onBgOpacityChanged: { if (bgOpacity >= 0.95 && bgBlur) { bgBlur = false } if (_loaded) saveConfig() }
    onOverrideBgChanged: if (_loaded) saveConfig()
    onOverrideBorderChanged: if (_loaded) saveConfig()
    onOverrideActiveChanged: if (_loaded) saveConfig()
    onOverrideIconFontChanged: if (_loaded) saveConfig()
    onOverrideTextChanged: if (_loaded) saveConfig()
    onOverrideSubtextChanged: if (_loaded) saveConfig()
    onOverrideIconChanged: if (_loaded) saveConfig()

    function saveConfig() {
        var path = ShellState.userDataDir + "/shell_prefs.json"
        var data = JSON.stringify({
            customAvatarPath: root.customAvatarPath,
            bootFocusMode: root.bootFocusMode,
            focusModeHoverExpand: root.focusModeHoverExpand,
            defaultDashboardTab: root.defaultDashboardTab,
            defaultAudioTab: root.defaultAudioTab,
            use24HourTime: root.use24HourTime,
            alwaysShowBatteryPercentage: root.alwaysShowBatteryPercentage,
            alwaysShowVolumePercentage: root.alwaysShowVolumePercentage,
            animStyle: root.animStyle,
            animSpeed: root.animSpeed,
            animCurve: root.animCurve,
            autoUpdate: root.autoUpdate,
            screenrecCaptureTarget: root.screenrecCaptureTarget,
            screenrecAudioMic: root.screenrecAudioMic,
            screenrecAudioSystem: root.screenrecAudioSystem,
            screenrecFramerate: root.screenrecFramerate,
            screenrecBackend: root.screenrecBackend,
            screenrecSaveDir: root.screenrecSaveDir,
            hotspotSsid: root.hotspotSsid,
            hotspotPassword: root.hotspotPassword,
            shellLayout: root.shellLayout,
            floatingGap: root.floatingGap,
            floatingBarHeight: root.floatingBarHeight,
            barEnabled: root.barEnabled,
            borderWidth: root.borderWidth,
            cornerRadius: root.cornerRadius,
            outerGaps: root.outerGaps,
            sliderStyle: root.sliderStyle,
            wsMode: root.wsMode,
            wsCount: root.wsCount,
            wsShape: root.wsShape,
            wsSymbols: root.wsSymbols,
            wsSymbolStyle: root.wsSymbolStyle,
            wsShowCapsule: root.wsShowCapsule,
            wsInvertScroll: root.wsInvertScroll,
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
            enableOsd: root.enableOsd,
            osdDuration: root.osdDuration,
            enableVisualiser: root.enableVisualiser,
            dynamicThemeOverride: root.dynamicThemeOverride,
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

    function updateLayerBlur() {
        WM.setLayerBlur("brain-shell-frame", root.bgBlur, 0.1)
    }

    property Process _initProcPrefs: Process {
        command: []
        running: false
        onExited: (code) => {
            _configFile.path = ShellState.userDataDir + "/shell_prefs.json"
        }
    }
    property var _saveProc: Process { command: []; running: false }

    property var _wmConn: Connections {
        target: WM
        function onBackendChanged() {
            if (WM.backend && root._loaded && !ShellState.focusMode) {
                WM.setGaps(WM.gapsIn, root.outerGaps)
            }
        }
    }
}
