import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import "../theme"

// A morphing Wayland window layer for the unified screen frame
PanelWindow {
    id: root

    property var screen

    // The frame always fills the screen to draw the continuous border
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "brain-shell-frame"
    WlrLayershell.exclusiveZone: 15 // Reserves space for the thin frame edges (e.g. 15px)

    // Only accept clicks where our frame/notches are drawn
    mask: Region { item: surfaceShape }

    SurfaceShape {
        id: surfaceShape
        anchors.fill: parent
        
        // Expose notch states to the shape
        property int leftNotchHeight: 40
        property int leftNotchWidth: 180
        
        property int centerNotchHeight: 45
        property int centerNotchWidth: 250
        
        property int rightNotchHeight: 40
        property int rightNotchWidth: 180

        Behavior on centerNotchHeight { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on centerNotchWidth { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on leftNotchHeight { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on leftNotchWidth { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on rightNotchHeight { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on rightNotchWidth { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    }
}
