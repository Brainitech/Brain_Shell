import QtQuick
import "../"

// A single horizontal label / value pair.
// Label is dimmed, value is bright by default.
// valueColor can be overridden for highlights (e.g. up/down arrows).

Item {
    id: root

    property string label:      ""
    property string value:      ""
    property color  valueColor: Theme.text
    property real   localScale: 1.0

    implicitHeight: Math.round(20 * localScale)

    Text {
        anchors.left:           parent.left
        anchors.verticalCenter: parent.verticalCenter
        text:           root.label
        font.pixelSize: Math.round(11 * localScale)
        color:          Theme.subtext
    }

    Text {
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter
        text:           root.value
        font.pixelSize: Math.round(11 * localScale)
        color:          root.valueColor
    }
}
