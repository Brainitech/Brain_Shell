import QtQuick
import "../../components"
import "../../components"
import "../../"

IconBtn {
    text: ""
    textColor: "#1793d1"
    onClicked: {
        if (!Popups.archMenuOpen) {
            SurfaceState.open("leftCenter", "archMenu")
            Popups.archMenuPinned = true
        } else {
            SurfaceState.close()
        }
    }
}
