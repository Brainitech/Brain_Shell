import QtQuick
import "../"

Item {
    id: root
    property real localScale: 1.0
    property string title: ""
    property string description: ""
    default property alias content: innerCol.data

    width: parent ? parent.width : 400
    height: headerCol.height + card.height + Math.round(8 * localScale)

    Column {
        id: headerCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: Math.round(4 * localScale)

        Text {
            visible: root.title !== ""
            text: root.title
            color: Theme.text
            font.pixelSize: Math.round(14 * localScale)
            font.weight: Font.DemiBold
            leftPadding: Math.round(4 * localScale)
        }
        Text {
            visible: root.description !== ""
            text: root.description
            color: Qt.rgba(1, 1, 1, 0.4)
            font.pixelSize: Math.round(11 * localScale)
            leftPadding: Math.round(4 * localScale)
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    Rectangle {
        id: card
        anchors {
            top: headerCol.bottom
            topMargin: Math.round(8 * localScale)
            left: parent.left
            right: parent.right
        }
        height: innerCol.height + Math.round(16 * localScale)
        radius: Math.round(Theme.cornerRadius * localScale)
        color: Qt.rgba(1, 1, 1, 0.04)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        Column {
            id: innerCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Math.round(8 * localScale)
            }
            spacing: Math.round(4 * localScale)
        }
    }
}
