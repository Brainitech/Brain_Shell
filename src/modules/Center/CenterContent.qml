import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "../../theme/"

Item {
    width: 150 // Max width for the center notch content
    height: 30
    
    // The "Carousel" or List
    ListView {
        id: statusList
        anchors.fill: parent
        orientation: ListView.Vertical
        spacing: 15
        clip: true // Cut off text that slides out
        
        // This makes it snap to items when you scroll
        snapMode: ListView.SnapOneItem 
        
		model: ObjectModel {
			Text {
				width: 150; height: 30
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
				text: "Work In Progress"
				color: "#ffffff"
			}
            // Item 1: Active Window
            Text {
                width: 150; height: 30
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"
                color: Theme.text
                elide: Text.ElideRight
            }

            // Item 3: Hostname (Static for now)
            Text {
                width: 150; height: 30
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: "ArchLinux" 
                color: "#FFFFFF"
            }
        }
    }

    // "Open menu will be control panel"
    MouseArea {
        anchors.fill: parent
        onClicked: console.log("Open Control Panel")
    }
}