import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import "../components"

// The new unified root for the morphing UI
ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        
        delegate: Item {
            id: screenRoot
            required property var modelData
            readonly property var screen: modelData
            
            // The morphing unified screen frame
            DynamicSurface {
                screen: screenRoot.screen
            }
            // To be implemented: 
            // - Top Morphing Surface (DynamicSurface.qml)
            // - Left Morphing Surface
            // - Right Morphing Surface
            // - Bottom Morphing Surface
        }
    }
}
