import QtQuick
import "../../components"
import "../../"

IconBtn {
		text: "" 
		textColor: "#1793d1"
		    onClicked: {
        var next = !Popups.archMenuOpen
        Popups.closeAll()
        Popups.archMenuOpen = next
    }
    
        // ── Hover → show trigger state for AudioPopup hover-to-open ──────────────
    HoverHandler {
        id: hov
        onHoveredChanged: Popups.archMenuTriggerHovered = hovered
    }
	}
