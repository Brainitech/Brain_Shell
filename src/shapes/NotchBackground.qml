// src/components/NotchBackground.qml
import QtQuick
import "../theme/" // To access Theme

Item {
    anchors.fill: parent
    
    // 1. The main shape with rounded corners
    Rectangle {
        anchors.fill: parent
        color: Theme.background
        radius: Theme.notchRadius
    }

    // 2. A "Patch" to square off the top corners
    // This sits at the top half and hides the top rounded corners
    Rectangle {
        height: parent.radius
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        color: Theme.background
    }
}