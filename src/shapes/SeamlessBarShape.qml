import QtQuick
import "../"

Canvas {
    id: root
    anchors.fill: parent

    property int notchHeight: Theme.notchHeight
    property int radius: 15         // Radius of the curves
    property int topBorderWidth: Theme.borderWidth  // Thickness of the connecting top border
    property color color: Theme.background
    
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        
        // --- Configuration ---
        var leftW =   Theme.lNotchWidth   
        var centerW = Theme.cNotchWidth 
        var rightW =  Theme.rNotchWidth  
        
        var r = root.radius
        var h = root.notchHeight
        var b = root.topBorderWidth // The "thin" height in the gaps
        var w = width
        
        // Calculated Positions
        var centerStart = (w / 2) - (centerW / 2)
        var centerEnd = (w / 2) + (centerW / 2)
        var rightStart = w - rightW

        ctx.beginPath();
        ctx.fillStyle = root.color;
        
        // ============================
        // 1. LEFT NOTCH SECTION
        // ============================
        // Start at Bottom-Left (Flush with screen edge)
        ctx.moveTo(0, h); 
        
        // Bottom Edge
        ctx.lineTo(leftW - r, h);
        
        // Bottom-Right Corner (Hanging -> Convex/Round)
        ctx.arcTo(leftW, h, leftW, h - r, r);
        
        // Right Edge Up (Stop before the top border!)
        ctx.lineTo(leftW, b + r);
        
        // Connection to Top Border (Melt -> Concave/Inward)
        // Control Point: (leftW, b) -> The inner corner of the intersection
        ctx.arcTo(leftW, b, leftW + r, b, r);


        // ============================
        // 2. GAP 1 (Left -> Center)
        // ============================
        // Line across the gap at border height
        ctx.lineTo(centerStart - r, b);


        // ============================
        // 3. CENTER NOTCH SECTION
        // ============================
        // Connection from Top Border (Melt -> Concave/Inward)
        // Control Point: (centerStart, b)
        ctx.arcTo(centerStart, b, centerStart, b + r, r);
        
        // Left Edge Down
        ctx.lineTo(centerStart, h - r);
        
        // Bottom-Left Corner (Hanging -> Convex/Round)
        ctx.arcTo(centerStart, h, centerStart + r, h, r);
        
        // Bottom Edge
        ctx.lineTo(centerEnd - r, h);
        
        // Bottom-Right Corner (Hanging -> Convex/Round)
        ctx.arcTo(centerEnd, h, centerEnd, h - r, r);
        
        // Right Edge Up
        ctx.lineTo(centerEnd, b + r);
        
        // Connection to Top Border (Melt -> Concave/Inward)
        // Control Point: (centerEnd, b)
        ctx.arcTo(centerEnd, b, centerEnd + r, b, r);


        // ============================
        // 4. GAP 2 (Center -> Right)
        // ============================
        // Line across the gap at border height
        ctx.lineTo(rightStart - r, b);


        // ============================
        // 5. RIGHT NOTCH SECTION
        // ============================
        // Connection from Top Border (Melt -> Concave/Inward)
        // Control Point: (rightStart, b)
        ctx.arcTo(rightStart, b, rightStart, b + r, r);
        
        // Left Edge Down
        ctx.lineTo(rightStart, h - r);
        
        // Bottom-Left Corner (Hanging -> Convex/Round)
        ctx.arcTo(rightStart, h, rightStart + r, h, r);
        
        // Bottom Edge
        ctx.lineTo(w, h); // Flush with right screen edge
        
        // ============================
        // 6. CLOSING THE LOOP
        // ============================
        // Right Screen Edge Up
        ctx.lineTo(w, 0);
        // Top Screen Edge Across (Back to 0,0)
        ctx.lineTo(0, 0);
        // Left Screen Edge Down (Back to Start)
        ctx.lineTo(0, h);
        
        ctx.fill();
    }
}
