import QtQuick
import "../"

Rectangle {
    id: root
    property real localScale: 1.0
    width: Math.round(24 * localScale)
    height: Math.round(24 * localScale)
    radius: Math.round(4 * localScale)
    
    // 1. Correct: referencing the ID 'hover' directly works here
    color: hover.hovered ? Theme.active : "transparent"
    
    property string text: "" 
    property color textColor: Theme.text
    signal clicked()

    Text {
        anchors.centerIn: parent
        text: root.text
        
        // 2. FIX: Changed 'root.hoverHandler.hovered' to 'hover.hovered'
        color: hover.hovered ? Theme.background : root.textColor
        
        font.pixelSize: Math.round(14 * localScale)
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
