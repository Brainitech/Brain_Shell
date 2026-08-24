import QtQuick
import QtQuick.Shapes
import "../theme"

Shape {
    id: root
    
    // Force ultra-smooth vector rendering
    antialiasing: true
    layer.enabled: true
    layer.samples: 8
    
    // Bindings to existing setup
    property int frameThickness: Theme.borderWidth
    property int innerRadius: Theme.cornerRadius
    property int flareRadius: Theme.notchRadius
    property color frameColor: Theme.background
    
    property int leftNotchHeight: 40
    property int leftNotchWidth: 180
    
    property int centerNotchHeight: 40
    property int centerNotchWidth: 300
    
    property int rightNotchHeight: 40
    property int rightNotchWidth: 180

    readonly property real t: frameThickness
    readonly property real r: innerRadius
    readonly property real fr: flareRadius
    readonly property real w: width
    readonly property real h: height

    ShapePath {
        fillColor: frameColor
        strokeColor: "transparent"
        strokeWidth: 0
        fillRule: ShapePath.OddEvenFill
        
        // --- OUTER BOUNDARY (Clockwise) ---
        startX: 0; startY: 0
        PathLine { x: w; y: 0 }
        PathLine { x: w; y: h }
        PathLine { x: 0; y: h }
        PathLine { x: 0; y: 0 }
        
        // --- CONNECT TO INNER ---
        PathLine { x: t; y: t + leftNotchHeight + fr }
        
        // --- INNER BOUNDARY (Counter-Clockwise) ---
        
        // Left screen edge going down
        PathLine { x: t; y: h-t-r }
        
        // Bottom-Left inner corner (Convex)
        PathArc { x: t+r; y: h-t; radiusX: r; radiusY: r; direction: PathArc.Counterclockwise }
        
        // Bottom screen edge going right
        PathLine { x: w-t-r; y: h-t }
        
        // Bottom-Right inner corner (Convex)
        PathArc { x: w-t; y: h-t-r; radiusX: r; radiusY: r; direction: PathArc.Counterclockwise }
        
        // Right screen edge going up, stopping below Right Notch melt
        PathLine { x: w-t; y: t + rightNotchHeight + fr }
        
        // RIGHT NOTCH (Flush to right edge)
        // Right notch melt (Concave, curves up and left into the notch bottom)
        PathArc { x: w-t-fr; y: t + rightNotchHeight; radiusX: fr; radiusY: fr; direction: PathArc.Counterclockwise }
        
        // Bottom edge of right notch
        PathLine { x: w-t - rightNotchWidth + r; y: t + rightNotchHeight }
        
        // Bottom-left curve of right notch (Convex)
        PathArc { x: w-t - rightNotchWidth; y: t + rightNotchHeight - r; radiusX: r; radiusY: r; direction: PathArc.Clockwise }
        
        // Left vertical edge of right notch going up to the top border flare
        PathLine { x: w-t - rightNotchWidth; y: t + fr }
        
        // Left flare of right notch (Concave)
        PathArc { x: w-t - rightNotchWidth - fr; y: t; radiusX: fr; radiusY: fr; direction: PathArc.Counterclockwise }
        
        // Top screen edge going left towards center notch
        PathLine { x: (w/2) + (centerNotchWidth/2) + fr; y: t }
        
        // CENTER NOTCH
        // Right flare of center notch (Concave)
        PathArc { x: (w/2) + (centerNotchWidth/2); y: t + fr; radiusX: fr; radiusY: fr; direction: PathArc.Counterclockwise }
        
        // Right vertical edge of center notch
        PathLine { x: (w/2) + (centerNotchWidth/2); y: t + centerNotchHeight - r }
        
        // Bottom-right curve of center notch (Convex)
        PathArc { x: (w/2) + (centerNotchWidth/2) - r; y: t + centerNotchHeight; radiusX: r; radiusY: r; direction: PathArc.Clockwise }
        
        // Bottom edge of center notch
        PathLine { x: (w/2) - (centerNotchWidth/2) + r; y: t + centerNotchHeight }
        
        // Bottom-left curve of center notch (Convex)
        PathArc { x: (w/2) - (centerNotchWidth/2); y: t + centerNotchHeight - r; radiusX: r; radiusY: r; direction: PathArc.Clockwise }
        
        // Left vertical edge of center notch
        PathLine { x: (w/2) - (centerNotchWidth/2); y: t + fr }
        
        // Left flare of center notch (Concave)
        PathArc { x: (w/2) - (centerNotchWidth/2) - fr; y: t; radiusX: fr; radiusY: fr; direction: PathArc.Counterclockwise }
        
        // Top screen edge going left towards left notch
        PathLine { x: t + leftNotchWidth + fr; y: t }
        
        // LEFT NOTCH (Flush to left edge)
        // Right flare of left notch (Concave)
        PathArc { x: t + leftNotchWidth; y: t + fr; radiusX: fr; radiusY: fr; direction: PathArc.Counterclockwise }
        
        // Right vertical edge of left notch
        PathLine { x: t + leftNotchWidth; y: t + leftNotchHeight - r }
        
        // Bottom-right curve of left notch (Convex)
        PathArc { x: t + leftNotchWidth - r; y: t + leftNotchHeight; radiusX: r; radiusY: r; direction: PathArc.Clockwise }
        
        // Bottom edge of left notch
        PathLine { x: t + fr; y: t + leftNotchHeight }
        
        // Left melt (Concave, curves down and left into the left frame)
        PathArc { x: t; y: t + leftNotchHeight + fr; radiusX: fr; radiusY: fr; direction: PathArc.Counterclockwise }
        
        // Close inner loop
        PathLine { x: t; y: t + leftNotchHeight + fr }
    }
}
