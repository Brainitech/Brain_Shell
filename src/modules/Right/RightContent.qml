import QtQuick
import Quickshell
import "../../components"
import "../../windows"
import "../../"
import "../../theme"

Item {
    id: root

    // The TopBar State handles expanding the notch for notifications/network/toasts
    implicitWidth: contentRow.implicitWidth

    implicitHeight: contentRow.implicitHeight

    // ── Normal content — fades out when any right popup opens ─────────────────
    Row {
        id: contentRow
        //anchors.centerIn: parent
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        opacity: (Popups.notificationsOpen || Popups.networkOpen) ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.standardSmall; easing.type: Anim.easing("standard").type; easing.bezierCurve: Anim.easing("standard").bezierCurve } }

        Network{}
        Audio{}
        Battery{}
        Clock{}
        SysTray{}
        Notifications{}
    }

    // ── Open indicator — fades in when any right popup opens ──────────────────
    Text {
        anchors.centerIn: parent
        text:           "▾"
        color:          Theme.active
        font.pixelSize: 14
        opacity:        (Popups.notificationsOpen || Popups.networkOpen) ? 1 : 0
        visible:        opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.standardSmall; easing.type: Anim.easing("standard").type; easing.bezierCurve: Anim.easing("standard").bezierCurve } }
    }
}
