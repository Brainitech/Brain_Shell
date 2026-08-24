pragma Singleton
import QtQuick

QtObject {
    id: root
    
    // Physical state of the morphing surfaces
    property string activeSurface: "none" // "none", "top", "left", "right", "bottom"
    property string activeContent: "none" // "dashboard", "archMenu", "audio", "network", "notifications"

    // Global toggle logic
    function toggle(surface, content) {
        if (activeSurface === surface && activeContent === content) {
            close()
        } else {
            open(surface, content)
        }
    }

    function open(surface, content) {
        root.activeSurface = surface
        root.activeContent = content
    }

    function close() {
        root.activeSurface = "none"
        root.activeContent = "none"
    }

    // Helper booleans for property binding
    readonly property bool isTopExpanded: activeSurface === "top"
    readonly property bool isLeftExpanded: activeSurface === "left"
    readonly property bool isRightExpanded: activeSurface === "right"
    readonly property bool isBottomExpanded: activeSurface === "bottom"
}
