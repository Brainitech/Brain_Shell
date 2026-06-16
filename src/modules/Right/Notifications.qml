import QtQuick
import Quickshell.Services.SystemTray
import "../../components"
import "../../windows"
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
        Popups.notificationsOpen = next
    }
}