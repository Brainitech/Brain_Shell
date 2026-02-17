import QtQuick
import Quickshell
import "../../components"
import "../../windows"
import "../../theme/" // Theme

Row {
	spacing: 5
	// Note: Do NOT add anchors.centerIn: parent here. TopBar handles that.

	// 1. Arch Icon (Power Menu Trigger)
	ControlPanel{}

	// 3. Vertical Separator
	Rectangle {
		width: 1; 
		height: 16
		color: Theme.border
		anchors.verticalCenter: parent.verticalCenter
	}

	// 4. Workspaces
	Workspaces {} 

	// 5. Vertical Separator
	Rectangle {
		width: 1; 
		height: 16
		color: Theme.border
		anchors.verticalCenter: parent.verticalCenter
	}

	// 6. Performance Control
	Performance{}
}
