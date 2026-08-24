import QtQuick
import Quickshell
import "../"

// A fullscreen invisible shield that catches clicks outside popups to close them
Item {
    id: root
    anchors.fill: parent
    
    // Only active when a surface is expanded
    property bool isActive: SurfaceState.activeSurface !== "none"
    
    TapHandler {
        enabled: root.isActive
        onTapped: {
            // Close all popups when clicking empty space
            SurfaceState.close()
        }
    }
}
