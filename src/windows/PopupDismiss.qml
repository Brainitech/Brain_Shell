import Quickshell
import Quickshell.Wayland
import QtQuick
import "../"
import Quickshell.Hyprland

// Transparent fullscreen overlay that dismisses all popups when:
//   - The user clicks anywhere on screen
//   - The user presses Escape
//
// Only active (visible + input-capturing) when Popups.anyOpen is true.
// Uses ExclusionMode.Ignore so it never reserves screen space.
// Sits on the Background layer so popups render above it.

PanelWindow {
    id: root

    color: "transparent"

    // Span entire screen
    anchors {
        top:    true
        left:   true
        right:  true
        bottom: true
    }
    
    margins.top: Theme.notchHeight // Start below the notch so it doesn't interfere with TopBar popups
    margins.left: Theme.borderWidth
    margins.right: Theme.borderWidth
    margins.bottom: Theme.borderWidth
    // Don't push windows away
    exclusionMode: ExclusionMode.Ignore

    // Only grab input when a popup is actually open
    // When false, input passes through as if this window doesn't exist
    visible: Popups.anyOpen

    // Sit below popups but above the desktop
    WlrLayershell.layer: WlrLayer.Top
    
    // Detech Keyboard events for Escape key to dismiss popups
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // --- Click anywhere to dismiss ---
    MouseArea {
        anchors.fill: parent
        onClicked:    Popups.closeAll()
    }

    // --- Escape to dismiss ---
    // Item must be focused for Keys to fire
    Item {
        anchors.fill: parent
        focus:        root.visible

        Keys.onEscapePressed: Popups.closeAll()
    }
    
        Connections {
        target: Hyprland
        
        // Quickshell emits (name, data) for raw events
        function onRawEvent(event) {
			// console.log("RawEvent_name: "+ event.name)
			// console.log("RawEvent_data: "+ event.data)
            // 1. Handle Scratchpad Toggle
            if (event.name === "workspace") {
                Popups.closeAll();
            }
            
            // 2. Reset when switching to a normal workspace
            if (event.name === "activespecial") {
                Popups.closeAll();
            }
        }
    }
}
