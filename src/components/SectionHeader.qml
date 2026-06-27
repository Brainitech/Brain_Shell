import QtQuick
import "../"

Item {
    id: root
    property real localScale: 1.0
    property string text: "Section Header"
    property string description: ""

    width: parent ? parent.width : 400
    height: Math.round(description !== "" ? (40 * localScale) : (24 * localScale))

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(4 * localScale)

        Text {
            text: root.text
            color: Theme.text
            font.pixelSize: Math.round(14 * localScale)
            font.weight: Font.DemiBold
        }

        Text {
            visible: root.description !== ""
            text: root.description
            color: Theme.subtext
            font.pixelSize: Math.round(11 * localScale)
        }
    }

    // Divider line
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Math.max(1, Math.round(1 * localScale))
        color: Theme.border
    }
}
