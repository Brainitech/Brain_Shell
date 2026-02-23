import QtQuick
import Quickshell
import "../shapes"
import "../"

// Audio popup — grows downward from the right notch of the TopBar.
// Width tracks the actual right notch width (passed in from TopBar).
// Height is clamped between Theme.popupMinHeight and Theme.popupMaxHeight.
//
// Usage in TopBar.qml:
//   AudioPopup { anchorWindow: root; notchWidth: root.rWidth }

PopupWindow {
    id: root

    required property var anchorWindow

    // The actual right-notch width — kept in sync by TopBar
    property int notchWidth: Theme.rNotchMinWidth

    // Desired content size before clamping
    property int contentWidth:  notchWidth
    property int contentHeight: 300

    // Final clamped popup dimensions
    readonly property int popupWidth: Math.max(
        Theme.popupMinWidth,
        Math.min(Theme.popupMaxWidth, contentWidth)
    )
    readonly property int popupHeight: Math.max(
        Theme.popupMinHeight,
        Math.min(Theme.popupMaxHeight, contentHeight)
    )

    // ── Window setup ─────────────────────────────────────────────────────────
    color:   "transparent"
    visible: Popups.audioOpen

    implicitWidth:  popupWidth
    implicitHeight: popupHeight

    // Position: flush under the right notch, right-aligned to screen edge
    anchor.window: anchorWindow
    anchor.rect: Qt.rect(
        anchorWindow.width,   // x — right edge of the bar window
        popupHeight + 50,     // y — just below the bar
        popupWidth,
        popupHeight
    )
    anchor.gravity: Edges.Bottom

    // ── Background ───────────────────────────────────────────────────────────
    PopupShape {
        id: bg
        anchors.fill: parent
        attachedEdge: "right"
        color:        Theme.background
        radius:       Theme.notchRadius
    }

    // ── Content ──────────────────────────────────────────────────────────────
    Item {
        anchors {
            fill:          parent
            topMargin:     bg.radius
            leftMargin:    4
            rightMargin:   4
            bottomMargin:  4
        }

        Text {
            anchors.centerIn: parent
            text:           "🔊 Audio Controls"
            color:          Theme.text
            font.pixelSize: 13
        }
    }
}
