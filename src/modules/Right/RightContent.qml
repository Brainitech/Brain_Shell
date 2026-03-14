import QtQuick
import Quickshell
import "../../components"
import "../../windows"
import "../../"

Item {
    id: root

    // Expand to fill the notch when notifications are open so the
    // ▾ indicator is truly centered in the expanded notch width.
    implicitWidth:  Popups.notificationsOpen
                    ? Theme.notificationsWidth
                    : contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight

    // ── Normal content — fades out when popup opens ───────────
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        opacity: Popups.notificationsOpen ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Network{}
        Audio{}
        Battery{}
        Clock{}
        SysTray{}
        Notifications{}
    }

    // ── Open indicator — fades in when popup opens ────────────
    Text {
        anchors.centerIn: parent
        text:           "▾"
        color:          Theme.active
        font.pixelSize: 14
        opacity:        Popups.notificationsOpen ? 1 : 0
        visible:        opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
}
