import QtQuick
import "../"

// Reusable card background. Wrap any stats panel in this for
// a consistent surface across the stats tab and future dashboard panels.
//
// Usage:
//   StatCard {
//       width: ...; height: ...
//       SomeContent { anchors.fill: parent }
//   }

Item {
    id: root

    default property alias content: inner.data
    property int  padding:    12
    property real localScale: 1.0

    Rectangle {
        anchors.fill: parent
        radius:       Math.round(Theme.cornerRadius * localScale)
        color:        Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
        border.color: Theme.border
        border.width: 1
    }

    Item {
        id: inner
        anchors {
            fill:         parent
            margins:      root.padding
        }
    }
}
