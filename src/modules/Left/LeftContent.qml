import QtQuick
import "../../components"
import "../../"

Row {
	property real localScale: 1.0
	height:  parent.height
	spacing: Math.round(5 * localScale)
	// Note: Do NOT add anchors.centerIn: parent here. TopBar handles that.

	// 1. Arch Icon (Power Menu Trigger)
	ControlPanel{ 
		localScale: parent.localScale
		anchors.verticalCenter: parent.verticalCenter
	}

	// 2. Workspaces
	Workspaces { 
		localScale: parent.localScale
		anchors.verticalCenter: parent.verticalCenter
	} 
	
	//3. LayoutDisplay
	LayoutDisplayer { 
		localScale: parent.localScale
		anchors.verticalCenter: parent.verticalCenter
	}

}
