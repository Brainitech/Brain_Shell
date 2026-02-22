// src/windows/TopBar.qml
import Quickshell
import QtQuick
import "../components"
import "../modules/Center/"
import "../modules/Right/"
import "../modules/Left/"
import "../"
import "../shapes/"

PanelWindow {
    id: root
    
    // Screen name property (set from shell.qml)
    property string screenName: screen ? screen.name : ""

    // 0. Setup - Transparent so only the shape shows
    color: "transparent"
    
    // 1. Anchors - Span the entire top
    anchors {
        top: true
        left: true
        right: true
    }
    
    // 2. Height - Enough to fit the notches
    implicitHeight: Theme.notchHeight // Extra space for shadows if needed
    exclusiveZone: Theme.notchHeight

    // 3. Background Shape
    SeamlessBarShape {
        anchors.fill: parent
    }

    // 4. Content Layouts
    // We manually place the content modules over the drawn shapes
    
    // Left Content
    Item {
        implicitHeight: Theme.notchHeight
        implicitWidth: 	Theme.lNotchWidth
        anchors.left: parent.left
        
        LeftContent {
            anchors.centerIn: parent
        }
    }

    // Center Content
    Item {
    	implicitHeight: Theme.notchHeight
        implicitWidth: Theme.cNotchWidth
        anchors.centerIn: parent
        
        CenterContent {
            anchors.centerIn: parent
        }
    }

    // Right Content
    Item {
        implicitHeight: Theme.notchHeight
        implicitWidth: Theme.rNotchWidth
        anchors.right: parent.right
        
        RightContent {
            anchors.centerIn: parent
        }
    }
}
