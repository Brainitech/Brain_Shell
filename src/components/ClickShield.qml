import QtQuick
import Quickshell
import "../"

// A fullscreen invisible shield that catches clicks outside popups to close them
Item {
    id: root
    anchors.fill: parent
    
    // Only active when a surface is expanded
    property bool isActive: SurfaceState.activeSurface !== "none" || (ShellState.screenRecord && !ScreenRecService.recording)
    
    MouseArea {
        anchors.fill: parent
        enabled: root.isActive
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: SurfaceState.close()
    }
}
