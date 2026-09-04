import QtQuick
import Quickshell
import "../components"
import "../services/"
import "../"

Item {
    id: root
    onOpacityChanged: if (opacity === 1) forceActiveFocus()
    Keys.onEscapePressed: SurfaceState.close()

    property real localScale: 1.0

    readonly property int popupWidth:   Math.round(Theme.notificationsWidth * root.localScale)
    readonly property int maxHeight:    Math.round(700 * root.localScale)
            readonly property int animDuration: Anim.transition

    // Fixed — never zero, never dynamic
    implicitWidth:  popupWidth
    implicitHeight: maxHeight



    // ── Content ─────────────────────────────────────────
    property int targetHeight: Math.min(
        Math.round(700 * root.localScale),
        notifList.height + Math.round(Theme.popupPadding * 2 * root.localScale) + Math.round(8 * root.localScale)
    )

    Item {
        anchors.fill: parent
        anchors.topMargin: Math.round(8 * root.localScale)
        anchors.leftMargin: Math.round(8 * root.localScale)
        anchors.rightMargin: Math.round(8 * root.localScale)
        anchors.bottomMargin: Math.round(8 * root.localScale)

        MouseArea { anchors.fill: parent }

        TapHandler {
            onTapped: {
                SurfaceState.open("right", "notifications")
                Popups.notificationsPinned = true
            }
        }

        opacity: (SurfaceState.activeContent === "notifications") ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: (SurfaceState.activeContent === "notifications") ? root.animDuration * 0.5 : root.animDuration * 0.15
            }
        }

        NotificationList {
            id:    notifList
            localScale: root.localScale
            width: parent.width
        }
    }
}
