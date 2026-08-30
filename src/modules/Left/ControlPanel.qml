import QtQuick
import "../../components"
import "../../"

IconBtn {
		text: ""
		textColor: "#1793d1"
		onClicked: {
        var next = !Popups.archMenuOpen
        Popups.closeAll()
        SurfaceState.toggle("left", "archMenu")
        if (next) Popups.archMenuPinned = true
    }
}
