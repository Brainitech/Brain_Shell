import QtQuick
import QtQuick.Shapes
import "../theme"
import "../"

Shape {
    id: root
    
    antialiasing: true
    layer.enabled: true
    layer.samples: 8
    
    property int frameThickness: Math.round(Theme.borderWidth * localScale)
    property int innerRadius: Math.round(Theme.cornerRadius * localScale)
    property int flareRadius: Math.round(Theme.notchRadius * localScale)
    property real localScale: 1.0
    property color frameColor: Theme.background
    
    // --- TOP NOTCHES ---
    property real baseNotchHeight: Math.round(Theme.notchHeight * localScale)
    property real leftNotchWidth: 0.001
    property real leftNotchHeight: baseNotchHeight
    
    property real centerNotchWidth: 0.001
    property real centerNotchHeight: SurfaceState.isTopExpanded ? Math.round(Theme.dashboardHeight * localScale) : baseNotchHeight
    
    property real rightNotchWidth: 0.001
    property real rightNotchHeight: SurfaceState.isRightExpanded ? Math.round(Theme.popupMaxHeight * localScale) : baseNotchHeight

    // --- SIDE/BOTTOM NOTCHES (0px base, grow when opened) ---
    property real lcnDepth: SurfaceState.isLeftCenterExpanded ? Math.round(Theme.popupMaxWidth * localScale) : 0.001
    property real lcnHeight: SurfaceState.isLeftCenterExpanded ? Math.round(Theme.popupMaxHeight * localScale) : 0.001

    property real rcnDepth: SurfaceState.isRightCenterExpanded ? Math.round(Theme.popupMaxWidth * localScale) : 0.001
    property real rcnHeight: SurfaceState.isRightCenterExpanded ? Math.round(Theme.popupMaxHeight * localScale) : 0.001

    property real bcnDepth: SurfaceState.isBottomCenterExpanded ? Math.round(Theme.popupMaxHeight * localScale) : 0.001
    property real bcnWidth: SurfaceState.isBottomCenterExpanded ? Math.round(Theme.dashboardWidth * localScale) : 0.001

    // Seamless Corner Morphing properties for Bottom-Right
    property real brnDepth: SurfaceState.isBottomRightExpanded ? Math.round(Theme.popupMaxHeight * localScale) : 0.001
    property real brnWidth: SurfaceState.isBottomRightExpanded ? Math.round(Theme.popupMaxWidth * localScale) : innerRadius

    readonly property real t: frameThickness
    readonly property real r: innerRadius
    readonly property real fr: flareRadius
    readonly property real w: width
    readonly property real h: height

    // Dynamic radii for top notches
    readonly property real cnFr: Math.min(fr, centerNotchHeight)
    readonly property real cnR:  Math.min(r, centerNotchHeight)

    property bool _lnCollapsed: ShellState.focusMode && leftNotchHeight <= r + 2
    property bool _rnCollapsed: ShellState.focusMode && rightNotchHeight <= r + 2

    property real lnRightFlare: _lnCollapsed ? r : Math.min(fr, leftNotchHeight)
    property real lnLeftMelt:   _lnCollapsed ? 0.001 : Math.min(fr, leftNotchHeight)
    property real lnInnerR:     _lnCollapsed ? 0.001 : Math.min(r, leftNotchHeight)

    property real rnTopFlare:   _rnCollapsed ? r : Math.min(fr, rightNotchHeight)
    property real rnBottomMelt: _rnCollapsed ? 0.001 : Math.min(fr, rightNotchHeight)
    property real rnInnerR:     _rnCollapsed ? 0.001 : Math.min(r, rightNotchHeight)

    // Dynamic radii for side notches (clamps to 0.001 to draw straight lines when closed)
    readonly property real lcnFr: Math.min(fr, lcnDepth)
    readonly property real lcnR:  Math.min(r, lcnDepth)
    
    readonly property real rcnFr: Math.min(fr, rcnDepth)
    readonly property real rcnR:  Math.min(r, rcnDepth)
    
    readonly property real bcnFr: Math.min(fr, bcnDepth)
    readonly property real bcnR:  Math.min(r, bcnDepth)
    
    // Bottom-Right Corner Interpolation
    property real brnBottomFlareR: SurfaceState.isBottomRightExpanded ? fr : 0.001
    property real brnInnerR:       SurfaceState.isBottomRightExpanded ? r : 0.001
    property real brnTopFlareR:    SurfaceState.isBottomRightExpanded ? fr : r
    
    // --- ANIMATIONS ---
    Behavior on lnRightFlare    { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on lnLeftMelt      { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on lnInnerR        { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on rnTopFlare      { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on rnBottomMelt    { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on rnInnerR        { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    
    Behavior on brnBottomFlareR { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on brnInnerR       { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on brnTopFlareR    { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on centerNotchHeight { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on centerNotchWidth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on leftNotchHeight { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on leftNotchWidth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on rightNotchHeight { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on rightNotchWidth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    
    Behavior on lcnDepth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on lcnHeight { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on rcnDepth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on rcnHeight { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on bcnDepth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on bcnWidth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on brnDepth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on brnWidth { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }

    ShapePath {
        fillColor: frameColor
        strokeColor: "transparent"
        strokeWidth: 0
        fillRule: ShapePath.OddEvenFill
        
        // --- OUTER BOUNDARY ---
        startX: 0; startY: 0
        PathLine { x: w; y: 0 }
        PathLine { x: w; y: h }
        PathLine { x: 0; y: h }
        PathLine { x: 0; y: 0 }
        
        PathLine { x: t; y: t + leftNotchHeight + lnLeftMelt }
        
        // --- INNER BOUNDARY (Counter-Clockwise) ---
        
        // LEFT-CENTER NOTCH
        PathLine { x: t; y: (h/2) - (lcnHeight/2) - lcnFr }
        PathArc { x: t + lcnFr; y: (h/2) - (lcnHeight/2); radiusX: lcnFr; radiusY: lcnFr; direction: PathArc.Counterclockwise }
        PathLine { x: t + lcnDepth - lcnR; y: (h/2) - (lcnHeight/2) }
        PathArc { x: t + lcnDepth; y: (h/2) - (lcnHeight/2) + lcnR; radiusX: lcnR; radiusY: lcnR; direction: PathArc.Clockwise }
        PathLine { x: t + lcnDepth; y: (h/2) + (lcnHeight/2) - lcnR }
        PathArc { x: t + lcnDepth - lcnR; y: (h/2) + (lcnHeight/2); radiusX: lcnR; radiusY: lcnR; direction: PathArc.Clockwise }
        PathLine { x: t + lcnFr; y: (h/2) + (lcnHeight/2) }
        PathArc { x: t; y: (h/2) + (lcnHeight/2) + lcnFr; radiusX: lcnFr; radiusY: lcnFr; direction: PathArc.Counterclockwise }

        // Left edge going down to corner
        PathLine { x: t; y: h-t-r }
        PathArc { x: t+r; y: h-t; radiusX: r; radiusY: r; direction: PathArc.Counterclockwise }
        
        // BOTTOM-CENTER NOTCH
        PathLine { x: (w/2) - (bcnWidth/2) - bcnFr; y: h-t }
        PathArc { x: (w/2) - (bcnWidth/2); y: h-t - bcnFr; radiusX: bcnFr; radiusY: bcnFr; direction: PathArc.Counterclockwise }
        PathLine { x: (w/2) - (bcnWidth/2); y: h-t - bcnDepth + bcnR }
        PathArc { x: (w/2) - (bcnWidth/2) + bcnR; y: h-t - bcnDepth; radiusX: bcnR; radiusY: bcnR; direction: PathArc.Clockwise }
        PathLine { x: (w/2) + (bcnWidth/2) - bcnR; y: h-t - bcnDepth }
        PathArc { x: (w/2) + (bcnWidth/2); y: h-t - bcnDepth + bcnR; radiusX: bcnR; radiusY: bcnR; direction: PathArc.Clockwise }
        PathLine { x: (w/2) + (bcnWidth/2); y: h-t - bcnFr }
        PathArc { x: (w/2) + (bcnWidth/2) + bcnFr; y: h-t; radiusX: bcnFr; radiusY: bcnFr; direction: PathArc.Counterclockwise }

        // BOTTOM-RIGHT NOTCH (Flush to corner, seamlessly morphs to standard r corner)
        PathLine { x: (w-t) - brnWidth - brnBottomFlareR; y: h-t }
        PathArc { x: (w-t) - brnWidth; y: h-t - brnBottomFlareR; radiusX: brnBottomFlareR; radiusY: brnBottomFlareR; direction: PathArc.Counterclockwise }
        PathLine { x: (w-t) - brnWidth; y: h-t - brnDepth + brnInnerR }
        PathArc { x: (w-t) - brnWidth + brnInnerR; y: h-t - brnDepth; radiusX: brnInnerR; radiusY: brnInnerR; direction: PathArc.Clockwise }
        PathLine { x: (w-t) - brnTopFlareR; y: h-t - brnDepth }
        PathArc { x: (w-t); y: h-t - brnDepth - brnTopFlareR; radiusX: brnTopFlareR; radiusY: brnTopFlareR; direction: PathArc.Counterclockwise }
        
        // Right screen edge going up, stopping below Right Notch melt
        PathLine { x: w-t; y: (h/2) + (rcnHeight/2) + rcnFr }
        PathArc { x: w-t - rcnFr; y: (h/2) + (rcnHeight/2); radiusX: rcnFr; radiusY: rcnFr; direction: PathArc.Counterclockwise }
        PathLine { x: w-t - rcnDepth + rcnR; y: (h/2) + (rcnHeight/2) }
        PathArc { x: w-t - rcnDepth; y: (h/2) + (rcnHeight/2) - rcnR; radiusX: rcnR; radiusY: rcnR; direction: PathArc.Clockwise }
        PathLine { x: w-t - rcnDepth; y: (h/2) - (rcnHeight/2) + rcnR }
        PathArc { x: w-t - rcnDepth + rcnR; y: (h/2) - (rcnHeight/2); radiusX: rcnR; radiusY: rcnR; direction: PathArc.Clockwise }
        PathLine { x: w-t - rcnFr; y: (h/2) - (rcnHeight/2) }
        PathArc { x: w-t; y: (h/2) - (rcnHeight/2) - rcnFr; radiusX: rcnFr; radiusY: rcnFr; direction: PathArc.Counterclockwise }
        
        // Right edge up to Right Top Notch
        PathLine { x: w-t; y: t + rightNotchHeight + rnBottomMelt }
        
        // RIGHT NOTCH (Flush to right edge)
        // Right notch melt (Concave, curves up and left into the notch bottom)
        PathArc { x: w-t-rnBottomMelt; y: t + rightNotchHeight; radiusX: rnBottomMelt; radiusY: rnBottomMelt; direction: PathArc.Counterclockwise }
        
        // Bottom edge of right notch
        PathLine { x: w-t - rightNotchWidth + rnInnerR; y: t + rightNotchHeight }
        
        // Bottom-left curve of right notch (Convex)
        PathArc { x: w-t - rightNotchWidth; y: t + rightNotchHeight - rnInnerR; radiusX: rnInnerR; radiusY: rnInnerR; direction: PathArc.Clockwise }
        
        // Left vertical edge of right notch going up to the top border flare
        PathLine { x: w-t - rightNotchWidth; y: t + rnTopFlare }
        
        // Left flare of right notch (Concave)
        PathArc { x: w-t - rightNotchWidth - rnTopFlare; y: t; radiusX: rnTopFlare; radiusY: rnTopFlare; direction: PathArc.Counterclockwise }
        
        // Top screen edge going left towards center notch
        PathLine { x: (w/2) + (centerNotchWidth/2) + cnFr; y: t }
        
        // CENTER NOTCH
        // Right flare of center notch (Concave)
        PathArc { x: (w/2) + (centerNotchWidth/2); y: t + cnFr; radiusX: cnFr; radiusY: cnFr; direction: PathArc.Counterclockwise }
        
        // Right vertical edge of center notch
        PathLine { x: (w/2) + (centerNotchWidth/2); y: t + centerNotchHeight - cnR }
        
        // Bottom-right curve of center notch (Convex)
        PathArc { x: (w/2) + (centerNotchWidth/2) - cnR; y: t + centerNotchHeight; radiusX: cnR; radiusY: cnR; direction: PathArc.Clockwise }
        
        // Bottom edge of center notch
        PathLine { x: (w/2) - (centerNotchWidth/2) + cnR; y: t + centerNotchHeight }
        
        // Bottom-left curve of center notch (Convex)
        PathArc { x: (w/2) - (centerNotchWidth/2); y: t + centerNotchHeight - cnR; radiusX: cnR; radiusY: cnR; direction: PathArc.Clockwise }
        
        // Left vertical edge of center notch
        PathLine { x: (w/2) - (centerNotchWidth/2); y: t + cnFr }
        
        // Left flare of center notch (Concave)
        PathArc { x: (w/2) - (centerNotchWidth/2) - cnFr; y: t; radiusX: cnFr; radiusY: cnFr; direction: PathArc.Counterclockwise }
        
        // Top screen edge going left towards left notch
        PathLine { x: t + leftNotchWidth + lnRightFlare; y: t }
        
        // LEFT NOTCH (Flush to left edge)
        // Right flare of left notch (Concave)
        PathArc { x: t + leftNotchWidth; y: t + lnRightFlare; radiusX: lnRightFlare; radiusY: lnRightFlare; direction: PathArc.Counterclockwise }
        
        // Right vertical edge of left notch
        PathLine { x: t + leftNotchWidth; y: t + leftNotchHeight - lnInnerR }
        
        // Bottom-right curve of left notch (Convex)
        PathArc { x: t + leftNotchWidth - lnInnerR; y: t + leftNotchHeight; radiusX: lnInnerR; radiusY: lnInnerR; direction: PathArc.Clockwise }
        
        // Bottom edge of left notch
        PathLine { x: t + lnLeftMelt; y: t + leftNotchHeight }
        
        // Left melt (Concave, curves down and left into the left frame)
        PathArc { x: t; y: t + leftNotchHeight + lnLeftMelt; radiusX: lnLeftMelt; radiusY: lnLeftMelt; direction: PathArc.Counterclockwise }
        
        // Close inner loop
        PathLine { x: t; y: t + leftNotchHeight + lnLeftMelt }
    }
}
