pragma Singleton
import QtQuick

QtObject {
    // -- Colors --
    // property color background: "#475c57"
    property color background: "#1a282a"
    property color active:     "#a6d0f7"
    property color text:       "#cdd6f4"
    property color icon:       "#ffffff"
    property color border:     "#ffffff"

    // --- Workspace Visuals ---
    property color wsBackground: "#20000000"
    property color wsActive:     "#FFFFFF"
    property color wsOccupied:   "#80FFFFFF"
    property color wsEmpty:      "#30FFFFFF"
    property color wsOverlay:    "#CC1e1e2e"

    // -- Bar Sizes --
    property int borderWidth:   6
    property int cornerRadius:  17
    property int notchRadius:   15
    property int notchHeight:   40
    property int exclusionGap:  34
    property int spacing:       10

    // -- Notch Content Padding --
    // Space added around the content inside each notch
    property int notchPadding:           16   // horizontal padding each side
    property int notchHorizontalPadding: 20
    property int notchVerticalPadding:   10
    property int notchSideMargin:        10

    // -- Notch Width Constraints --
    // Each notch sizes itself to its content, clamped between min and max.
    property int lNotchMinWidth: 180
    property int lNotchMaxWidth: 360

    property int cNotchMinWidth: 300
    property int cNotchMaxWidth: 360

    property int rNotchMinWidth: 200
    property int rNotchMaxWidth: 360

    // -- Dashboard Dimensions --
    // Target size the center notch expands to when the dashboard is open.
    // Tune these values to taste.
    property int dashboardWidth:  900
    property int dashboardHeight: 520

    // -- Popup Size Constraints --
    property int popupMinWidth:  160
    property int popupMaxWidth:  420
    property int popupMinHeight:  80
    property int popupMaxHeight: 520

    // -- Workspace Dot Sizes --
    property int wsDotSize:     10
    property int wsActiveWidth: 24
    property int wsSpacing:     6
    property int wsPadding:     8
    property int wsRadius:      16
    
    // -- Animations --
    property int animDuration: 320
}
