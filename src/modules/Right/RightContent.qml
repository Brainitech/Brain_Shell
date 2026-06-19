import QtQuick
import Quickshell
import "../../components"
import "../../windows"
import "../../"

Item {
    id: root
    property real localScale: 1.0
    height: parent.height

    // The TopBar State handles expanding the notch for notifications/network/toasts
    implicitWidth: contentRow.implicitWidth

    //Behavior on implicitWidth {
    //    NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
    //}
    implicitHeight: parent.height

    // ── Normal content — fades out when any right popup opens ─────────────────
    Row {
        id: contentRow
        //anchors.centerIn: parent
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: Math.round(6 * localScale)

        opacity: (Popups.notificationsOpen || Popups.networkOpen) ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Network{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Audio{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Battery{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Clock{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        SysTray{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
        Notifications{ 
            localScale: root.localScale
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Open indicator — fades in when any right popup opens ──────────────────
    Text {
        anchors.centerIn: parent
        text:           "▾"
        color:          Theme.active
        font.pixelSize: Math.round(14 * localScale)
        opacity:        (Popups.notificationsOpen || Popups.networkOpen) ? 1 : 0
        visible:        opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
}
