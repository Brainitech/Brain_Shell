import QtQuick
import Quickshell.Services.SystemTray
import "../../components"
import "../../"

IconBtn{
    text: ""
    onClicked: {
        var next = !Popups.audioOpen
        Popups.closeAll()
        Popups.audioOpen = next
    }
}
