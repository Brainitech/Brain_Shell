import QtQuick
import Quickshell
import "../../components"
import "../../windows"
import "../../theme/" // Theme

IconBtn {
		text: "" 
		textColor: "#1793d1"
		onClicked: {
            console.log("Arch icon clicked on screen:", screenName)
        }
	}