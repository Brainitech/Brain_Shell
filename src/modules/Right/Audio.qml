import QtQuick
import "../../components"
import "../../"

IconBtn {
    text: ""

    // Report hover state so AudioPopup can open on hover
    // HoverHandler {
    //     onHoveredChanged: Popups.audioTriggerHovered = hovered
    // }

    onClicked: {
        var next = !Popups.audioOpen
        Popups.closeAll()
        Popups.audioOpen = next
    }
}
