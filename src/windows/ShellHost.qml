import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../components"

// The new unified root for the morphing UI
ShellRoot {
    id: screenRoot
    
    property var _keybinds: KeybindService
    property var _updater:  UpdateService
    property var _ipc:      IpcManager
    
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
                StrutWindow { screen: modelData; edge: "top"; reserveSpace: Math.round(40 * localScale) + Math.round(Theme.borderWidth * localScale) * 2 }
                StrutWindow { screen: modelData; edge: "bottom"; reserveSpace: Math.round(Theme.borderWidth * localScale) * 2 }
                StrutWindow { screen: modelData; edge: "left"; reserveSpace: Math.round(Theme.borderWidth * localScale) * 2 }
                StrutWindow { screen: modelData; edge: "right"; reserveSpace: Math.round(Theme.borderWidth * localScale) * 2 }
                
                // The morphing unified screen frame
                DynamicSurface {
                    screen: modelData
                }
                
                ConfirmDialog { screen: modelData }
                UpdatePopup { screen: modelData }
            }
        }
    }
}
