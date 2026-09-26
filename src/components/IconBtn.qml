import QtQuick
import "../"

Rectangle {
    id: root
    property real localScale: 1.0
    width: Math.round(24 * localScale)
    height: Math.round(24 * localScale)
    radius: Math.round(4 * localScale)
    
    color: hover.hovered ? Theme.active : "transparent"
    
    property string text: "" 
    property color textColor: Theme.text
    property int fontSize: Math.round(14 * localScale)
    signal clicked()

    Text {
        anchors.centerIn: parent
        text: root.text
        
        color: hover.hovered ? Theme.background : root.textColor
        
        font.pixelSize: root.fontSize
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
