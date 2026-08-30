import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"
import "../shapes/"
import "../services/"
import "../"

Item {
    id: root

    property real localScale: 1.0

    readonly property int popupWidth:   Math.round(Theme.notificationsWidth * root.localScale)
    readonly property int maxHeight:    Math.round(700 * root.localScale)
    readonly property int fw:           Math.round(Theme.notchRadius * root.localScale)
    readonly property int fh:           Math.round(Theme.notchRadius * root.localScale)
    readonly property int animDuration: Anim.transition

    // Fixed — never zero, never dynamic
    implicitWidth:  popupWidth + fw
    implicitHeight: maxHeight





    Connections {
        target: Popups

        function onNotificationsTriggerHoveredChanged() {
            if (Popups.notificationsTriggerHovered) {
                if (root.allowHover) {
                    hoverCloseTimer.stop()
                    hoverOpenTimer.restart()
                }
            } else {
                hoverOpenTimer.stop()
                if (root.allowHover && !root.selfHovered) hoverCloseTimer.restart()
            }
        }
    }

    property bool allowHover: Popups.notificationsAllowHover
    property bool pinned:     Popups.notificationsPinned
    property bool selfHovered: false

    onSelfHoveredChanged: {
        if (root.allowHover) {
            if (!selfHovered && !Popups.notificationsTriggerHovered) hoverCloseTimer.restart()
            else                                                     hoverCloseTimer.stop()
        }
    }

    Timer {
        id: hoverOpenTimer
        interval: Popups.hoverOpenDelay
        onTriggered: {
            if (root.allowHover && Popups.notificationsTriggerHovered) {
                if (!Popups.notificationsOpen) {
                    Popups.closeAll()
                    SurfaceState.open("right", "notifications")
                }
            }
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: Popups.hoverCloseDelay
        onTriggered: {
            if (root.allowHover && !Popups.notificationsTriggerHovered && !root.selfHovered) {
                if (!root.pinned) {
                    SurfaceState.close()
                }
            }
        }
    }




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

        HoverHandler {
            onHoveredChanged: root.selfHovered = hovered
        }

        TapHandler {
            onTapped: {
                SurfaceState.open("right", "notifications")
                Popups.notificationsPinned = true
            }
        }

        opacity: Popups.notificationsOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Popups.notificationsOpen ? root.animDuration * 0.5 : root.animDuration * 0.15
            }
        }

        NotificationList {
            id:    notifList
            localScale: root.localScale
            width: parent.width
        }
    }
}
