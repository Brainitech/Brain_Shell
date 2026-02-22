import QtQuick
import Quickshell
import "../shapes"
import "../"

// Audio popup - grows downward from the right notch of the TopBar.
// Instantiate this inside TopBar.qml so it has access to the PanelWindow.
//
// Usage in TopBar.qml:
//   AudioPopup { anchorWindow: root }
PopupWindow {
    id: root

    // The TopBar PanelWindow - must be set by the parent (TopBar.qml)
    required property var anchorWindow

    // Dimensions
    readonly property int popupWidth:  Theme.rNotchWidth
    readonly property int popupHeight: 300

    // --- Popup Window Setup ---
    color: "transparent"

    visible: Popups.audioOpen

    // Position: directly below the right notch, right-aligned to screen edge
    anchor.window: anchorWindow
    anchor.rect: Qt.rect(
        anchorWindow.width,  // x: right-aligned under right notch
        popupHeight+50,  // y: top of the bar
        popupWidth,
        popupHeight   // width and height of the anchor rect (notch size)
    )
    anchor.gravity: Edges.Bottom          // popup appears below the anchor rect

    implicitWidth:  popupWidth
    implicitHeight: popupHeight

    // --- Background Shape ---
    // top-attached: top edge is flush, concave top corners melt into the bar bottom
    PopupShape {
        id: bg
        anchors.fill: parent
        attachedEdge: "right"
        color: Theme.background
        radius: Theme.notchRadius  // matches SeamlessBarShape radius for seamless melting
    }

    // --- Content ---
    // Placeholder — replace with real audio controls
    Item {
        // Inset content so it doesn't render in the concave corner regions
        anchors {
            fill: parent
            topMargin: bg.radius
            leftMargin: 4
            rightMargin: 4
            bottomMargin: 4
        }

        Text {
            anchors.centerIn: parent
            text: "🔊 Audio Controls"
            color: Theme.text
            font.pixelSize: 13
        }
    }

    // Close when clicking outside (Escape or click-away)
    // PopupWindow closes itself when it loses focus if this is set:
    // closePolicy: PopupWindow.CloseOnEscape | PopupWindow.CloseOnPressOutside
    // For now, toggling via the button handles open/close.
}
