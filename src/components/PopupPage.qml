import QtQuick
import QtQuick.Controls
import "../"

// Reusable scrollable page container for popup content.
// Clips content, shows a faint scrollbar when needed.
// Consistent vertical padding relative to popup height.
//
// Usage:
//   PopupPage {
//       anchors.fill: parent
//       // children go here — laid out top-to-bottom, scrollable if overflow
//   }

Item {
    id: root

    // All children go into the scroll content
    default property alias content: contentCol.data

    property real localScale: 1.0

    // Padding applied inside the scroll area
    property int padH: Math.round(6 * localScale)   // horizontal
    property int padV: Math.round(8 * localScale)   // vertical

    clip: true

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth:  width
        contentHeight: contentCol.implicitHeight + root.padV * 2
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        // Scroll with mouse wheel
        ScrollBar.vertical: ScrollBar {
            policy: Math.ceil(contentCol.implicitHeight + root.padV * 2) > Math.floor(flick.height) + 2
                        ? ScrollBar.AlwaysOn
                        : ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth:  Math.round(3 * localScale)
                implicitHeight: Math.round(40 * localScale)
                radius:         width / 2
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
            }
            background: Item {}
        }

        Column {
            id: contentCol
            anchors {
                top:        parent.top
                topMargin:  root.padV
                left:       parent.left
                leftMargin: root.padH
                // Reserve space for scrollbar when visible
                right:      parent.right
                rightMargin: root.padH + Math.round(6 * localScale)
            }
            spacing: Math.round(8 * localScale)
        }
    }
}
