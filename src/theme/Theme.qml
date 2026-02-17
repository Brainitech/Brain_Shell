pragma Singleton
import QtQuick

QtObject {
    // -- Colors --
    property color background: "#475c57" // Base color
    property color active:     "#a6d0f7" // Accent
    property color text:       "#cdd6f4"
	property color icon:	   "#ffffff"
	property color border:	   "#ffffff"

	// --- Workspace Visuals ---
    property color wsBackground: "#20000000" // Capsule background
    property color wsActive:     "#FFFFFF"    // Bright White
    property color wsOccupied:   "#80FFFFFF"  // Dim White
    property color wsEmpty:      "#30FFFFFF"  // Greyed out
    
	property color wsOverlay:    "#CC1e1e2e"  // Scratchpad Overlay Colors

    // -- Sizes --
    property int borderWidth: 6        // Thickness of the screen edge borders
    property int cornerRadius: 10
	property int notchRadius: 12      // The roundness of the bottom corners
    property int notchHeight: 40
    property int lNotchWidth: 280
    property int cNotchWidth: 200
    property int rNotchWidth: 200
	property int spacing: 10
	property int wsDotSize:      10           // Diameter of the dots
    property int wsActiveWidth:  24           // Width of the active "pill" (stretch effect)
    property int wsSpacing:      6            // Space between dots
    property int wsPadding:      8            // Padding inside the capsule
    property int wsRadius:       16           // Radius of the main capsule          // Radius for the capsule container
    property int notchHorizontalPadding: 20
    property int notchVerticalPadding: 10
    property int notchSideMargin: 10
}