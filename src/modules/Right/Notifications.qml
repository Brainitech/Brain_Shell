import QtQuick
import "../../components"
import "../../components"
import "../../"
import "../../services/"

IconBtn {
    property real localScale: 1.0
    text: ShellState.dnd
          ? "󰂛"
          : NotificationService.count > 0 ? "󰂚" : "󰂜"

    onClicked: {
        var next = !Popups.notificationsOpen
        Popups.closeAll()
        SurfaceState.toggle("right", "notifications")
        if (next) Popups.notificationsPinned = true
    }

    HoverHandler {
        onHoveredChanged: Popups.notificationsTriggerHovered = hovered
    }
}