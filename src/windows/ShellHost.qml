import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../components"
import "../services"
import Quickshell.Services.Pipewire

// The new unified root for the morphing UI
ShellRoot {
    id: screenRoot
    
    property var _keybinds: KeybindService
    property var _updater:  UpdateService
    property var _ipc:      IpcManager
    property var _migrator: MigrationService
    

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                PrefsService.updateHyprlandBlur()
                WallpaperService.updateBorders()
                ShellState.applyZeroGaps()
            }
        }
    }

    // ── OSD Triggers ──────────────────────────────────────────────────────────
    property bool _isBooting: true
    Timer {
        id: bootGuardTimer
        interval: 3000
        running: true
        repeat: false
        onTriggered: screenRoot._isBooting = false
    }

    Timer {
        id: osdCloseTimer
        interval: 2500
        repeat: false
        onTriggered: {
            if (SurfaceState.activeContent === "quick" && !Popups.quickPinned && !Popups.quickTriggerHovered) {
                SurfaceState.close()
            }
        }
    }

    function _triggerOsd() {
        if (_isBooting) return;
        if (SurfaceState.activeContent === "none" || SurfaceState.activeContent === "notifications" || SurfaceState.activeContent === "quick") {
            if (SurfaceState.activeContent !== "quick") SurfaceState.open("rightCenter", "quick")
            osdCloseTimer.restart()
        }
    }

    Connections {
        target: BrightnessService
        function onExternalBrightnessChanged(val) {
            _triggerOsd()
        }
    }

    property var _sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    Connections {
        target: _sinkAudio
        ignoreUnknownSignals: true
        function onVolumeChanged() { _triggerOsd() }
        function onMutedChanged() { _triggerOsd() }
    }

    Variants {
        model: Quickshell.screens
        
        // Wrap everything in a standard Component for multi-monitor support
        delegate: Component {
            Item {
                required property var modelData
                readonly property var screen: modelData
                readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))
                
                // --- EXCLUSIVE ZONE STRUTS ---
                // Using phantom windows to seamlessly push active Hyprland windows inward
                // without requiring the user to manually edit hyprland.conf gaps.
                StrutWindow { 
                    screen: modelData; 
                    edge: "top"; 
                    reserveSpace: ShellState.focusMode ? Math.round(Theme.borderWidth * localScale) * 2 : Math.round(40 * localScale) + Math.round(Theme.borderWidth * localScale) * 2 
                    Behavior on reserveSpace { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
                }
                StrutWindow { screen: modelData; edge: "bottom"; reserveSpace: Math.round(Theme.borderWidth * localScale) * 2 }
                StrutWindow { screen: modelData; edge: "left"; reserveSpace: Math.round(Theme.borderWidth * localScale) * 2 }
                StrutWindow { screen: modelData; edge: "right"; reserveSpace: Math.round(Theme.borderWidth * localScale) * 2 }
                
                // The morphing unified screen frame
                DynamicSurface {
                    screen: modelData
                }
                
                ConfirmDialog { screen: modelData }
                UpdatePopup { screen: modelData }
                MigrationOverlay { screen: modelData }
            }
        }
    }
}
