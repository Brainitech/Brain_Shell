import QtQuick
import "../"

Item {
    id: root
    property real localScale: 1.0
    property string text: "Action Option"
    property string description: ""
    property string buttonText: "Click"
    property bool destructive: false
    signal clicked()

    width: parent ? parent.width : 400
    height: Math.round(description !== "" ? (52 * localScale) : (40 * localScale))

    // Background Hover Highlight
    Rectangle {
        anchors.fill: parent
        anchors.margins: 0
        radius: Math.round(8 * localScale)
        color: btnMouse.hovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        Behavior on color { ColorAnimation { duration: Anim.fast; easing.type: Anim.linear } }
    }

    Column {
        anchors {
            left: parent.left
            leftMargin: Math.round(8 * localScale)
            right: actionBtn.left
            rightMargin: Math.round(12 * localScale)
            verticalCenter: parent.verticalCenter
        }
        spacing: Math.round(4 * localScale)

        Text {
            text: root.text
            color: root.destructive ? "#f87171" : Theme.text
            font.pixelSize: Math.round(13 * localScale)
        }

        Text {
            visible: root.description !== ""
            text: root.description
            color: Qt.rgba(1, 1, 1, 0.4)
            font.pixelSize: Math.round(11 * localScale)
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    // Action Button
    Rectangle {
        id: actionBtn
        anchors {
            right: parent.right
            rightMargin: Math.round(8 * localScale)
            verticalCenter: parent.verticalCenter
        }
        width: btnLabel.implicitWidth + Math.round(24 * localScale)
        height: Math.round(24 * localScale)
        radius: Math.round(4 * localScale)
        color: btnMouse.pressed ? Qt.rgba(1, 1, 1, 0.15) : (btnMouse.hovered ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05))
        Behavior on color { ColorAnimation { duration: Anim.fast; easing.type: Anim.linear } }
        
        border.color: root.destructive ? Qt.rgba(248/255, 113/255, 113/255, 0.3) : Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        Text {
            id: btnLabel
            anchors.centerIn: parent
            text: root.buttonText
            color: root.destructive ? "#fca5a5" : Theme.text
            font.pixelSize: Math.round(11 * localScale)
            font.weight: Font.Medium
        }
    }

    HoverHandler {
        id: btnMouse
        cursorShape: Qt.PointingHandCursor
    }
    MouseArea {
        anchors.fill: actionBtn
        onClicked: root.clicked()
    }
}
