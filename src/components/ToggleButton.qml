import QtQuick
import "../"

Item {
    id: root
    property real localScale: 1.0
    property string text: "Toggle Option"
    property string description: ""
    property bool checked: false
    signal toggled()

    width: parent ? parent.width : 400
    height: Math.round(description !== "" ? (52 * localScale) : (40 * localScale))

    // Background Hover Highlight
    Rectangle {
        anchors.fill: parent
        anchors.margins: 0
        radius: Math.round(8 * localScale)
        color: toggleMouse.hovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        Behavior on color { ColorAnimation { duration: Anim.fast; easing.type: Anim.linear } }
    }

    Column {
        anchors {
            left: parent.left
            leftMargin: Math.round(8 * localScale)
            right: switchRect.left
            rightMargin: Math.round(12 * localScale)
            verticalCenter: parent.verticalCenter
        }
        spacing: Math.round(4 * localScale)

        Text {
            text: root.text
            color: Theme.text
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

    // Switch Track
    Rectangle {
        id: switchRect
        anchors {
            right: parent.right
            rightMargin: Math.round(8 * localScale)
            verticalCenter: parent.verticalCenter
        }
        width: Math.round(40 * localScale)
        height: Math.round(22 * localScale)
        radius: height / 2
        
        color: root.checked ? Theme.active : Qt.rgba(1, 1, 1, 0.1)
        Behavior on color { ColorAnimation { duration: Anim.fast; easing.type: Anim.linear } }
        
        border.color: root.checked ? Qt.darker(Theme.active, 1.2) : Qt.rgba(1, 1, 1, 0.2)
        border.width: Math.max(1, Math.round(1 * localScale))

        // Switch Handle
        Rectangle {
            width: Math.round(16 * localScale)
            height: Math.round(16 * localScale)
            radius: width / 2
            
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? (parent.width - width - Math.round(3 * localScale)) : Math.round(3 * localScale)
            
            Behavior on x { NumberAnimation { duration: Anim.fast; easing.type: Anim.globalCurve } }

            color: "white"
        }
    }

    HoverHandler {
        id: toggleMouse
        cursorShape: Qt.PointingHandCursor
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.checked = !root.checked
            root.toggled()
        }
    }
}
