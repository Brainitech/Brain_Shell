import QtQuick
import "../../components"
import "../../"
import "../../services/"

IconBtn {
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