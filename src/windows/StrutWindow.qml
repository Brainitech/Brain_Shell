import QtQuick
import Quickshell
import Quickshell.Wayland

// A phantom Wayland window used purely to reserve space (exclusive zone) for the compositor.
// This allows our fullscreen morphing canvas to remain unbroken while still pushing tiled windows away.
PanelWindow {
    property string edge: "top"
    property int reserveSpace: 40

    anchors {
        top: edge === "top"
        bottom: edge === "bottom"
        left: edge === "left"
        right: edge === "right"
    }
    
    // Size the phantom window to precisely the reserved space
    implicitWidth: (edge === "left" || edge === "right") ? reserveSpace : 100
    implicitHeight: (edge === "top" || edge === "bottom") ? reserveSpace : 100

    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Bottom // Kept out of the way
    WlrLayershell.namespace: "brain-shell-strut-" + edge
    WlrLayershell.exclusiveZone: reserveSpace
    
    // We don't want to accept ANY input on the strut window itself
    mask: Region {
        Region { x: 0; y: 0; width: 0; height: 0 }
    }
}
