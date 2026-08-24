import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../theme"

// A morphing Wayland window layer for the unified screen frame
PanelWindow {
    id: root
    property var screen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    // Counteract the compositor's usable area squish (caused by our StrutWindows)
    // by pushing the bounds back out to the absolute screen edges.
    margins {
        top: -40 -Theme.borderWidth *2
        bottom: -Theme.borderWidth *2
        left: -Theme.borderWidth *2
        right: -Theme.borderWidth *2
    }
    
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "brain-shell-frame"

    // --- MASK PROXIES ---
    // These track the exact boundaries so clicks pass through to Hyprland when empty
    Item { id: topMask; width: parent.width; height: surfaceShape.frameThickness }
    Item { id: bottomMask; width: parent.width; height: surfaceShape.frameThickness; anchors.bottom: parent.bottom }
    Item { id: leftMask; width: surfaceShape.frameThickness; height: parent.height }
    Item { id: rightMask; width: surfaceShape.frameThickness; height: parent.height; anchors.right: parent.right }
    
    Item { 
        id: leftNotchMask
        width: surfaceShape.leftNotchWidth + (surfaceShape.flareRadius * 2)
        height: surfaceShape.leftNotchHeight + surfaceShape.flareRadius
        x: 0
        TapHandler { 
            // Toggle open, but don't close if clicking inside the open content
            onTapped: if (!SurfaceState.isLeftExpanded) SurfaceState.open("left", "archMenu") 
        }
    }
    Item { 
        id: centerNotchMask
        width: surfaceShape.centerNotchWidth + (surfaceShape.flareRadius * 2)
        height: surfaceShape.centerNotchHeight + surfaceShape.flareRadius
        anchors.horizontalCenter: parent.horizontalCenter
        TapHandler { 
            onTapped: if (!SurfaceState.isTopExpanded) SurfaceState.open("top", "dashboard") 
        }
    }
    Item { 
        id: rightNotchMask
        width: surfaceShape.rightNotchWidth + (surfaceShape.flareRadius * 2)
        height: surfaceShape.rightNotchHeight + surfaceShape.flareRadius
        anchors.right: parent.right
        TapHandler { 
            onTapped: if (!SurfaceState.isRightExpanded) SurfaceState.open("right", "audio") 
        }
    }

    Item { 
        id: leftCenterNotchMask
        width: Math.max(100, surfaceShape.lcnDepth + (surfaceShape.flareRadius * 2))
        height: Math.max(200, surfaceShape.lcnHeight + (surfaceShape.flareRadius * 2))
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        TapHandler { onTapped: if (!SurfaceState.isLeftCenterExpanded) SurfaceState.open("leftCenter", "archMenu") }
    }
    Item { 
        id: rightCenterNotchMask
        width: Math.max(100, surfaceShape.rcnDepth + (surfaceShape.flareRadius * 2))
        height: Math.max(200, surfaceShape.rcnHeight + (surfaceShape.flareRadius * 2))
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        TapHandler { onTapped: if (!SurfaceState.isRightCenterExpanded) SurfaceState.open("rightCenter", "audio") }
    }
    Item { 
        id: bottomCenterNotchMask
        width: Math.max(300, surfaceShape.bcnWidth + (surfaceShape.flareRadius * 2))
        height: Math.max(100, surfaceShape.bcnDepth + (surfaceShape.flareRadius * 2))
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        TapHandler { onTapped: if (!SurfaceState.isBottomCenterExpanded) SurfaceState.open("bottomCenter", "wallpaper") }
    }
    Item { 
        id: bottomRightNotchMask
        width: Math.max(200, surfaceShape.brnWidth + (surfaceShape.flareRadius * 2))
        height: Math.max(100, surfaceShape.brnDepth + (surfaceShape.flareRadius * 2))
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        TapHandler { onTapped: if (!SurfaceState.isBottomRightExpanded) SurfaceState.open("bottomRight", "clipboard") }
    }

    // --- CLICK SHIELD ---
    ClickShield { id: clickShield }

    // Mask logic: Combine frame borders + active notches. 
    mask: Region { 
        Region { item: clickShield.isActive ? clickShield : null }
        Region { item: topMask }
        Region { item: bottomMask }
        Region { item: leftMask }
        Region { item: rightMask }
        Region { item: leftNotchMask }
        Region { item: centerNotchMask }
        Region { item: rightNotchMask }
        Region { item: leftCenterNotchMask }
        Region { item: rightCenterNotchMask }
        Region { item: bottomCenterNotchMask }
        Region { item: bottomRightNotchMask }
    }

    // --- VECTOR GEOMETRY ---
    SurfaceShape {
        id: surfaceShape
        anchors.fill: parent
        
        // Geometry animates with smooth CUBIC curve (never detaches)
        Behavior on centerNotchHeight { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on centerNotchWidth { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on leftNotchHeight { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on leftNotchWidth { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on rightNotchHeight { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on rightNotchWidth { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    }
    
    // Future content layers will be injected here
}
