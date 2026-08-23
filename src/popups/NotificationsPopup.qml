import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"
import "../shapes/"
import "../services/"
import "../"

PopupWindow {
    id: root
    required property var anchorWindow

    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    readonly property int popupWidth:   Math.round(Theme.notificationsWidth * root.localScale)
    readonly property int maxHeight:    Math.round(700 * root.localScale)
    readonly property int fw:           Math.round(Theme.notchRadius * root.localScale)
    readonly property int fh:           Math.round(Theme.notchRadius * root.localScale)
    readonly property int animDuration: Anim.transition

    // Fixed — never zero, never dynamic
    implicitWidth:  popupWidth + fw
    implicitHeight: maxHeight

    anchor.window: root.anchorWindow
    anchor.rect: Qt.rect(
        Math.round((anchorWindow ? anchorWindow.width : 0) - (popupWidth / 2) - fw + 1),
        0,
        Math.round(Theme.notificationsWidth * root.localScale),
        Math.round(Theme.notchHeight * root.localScale)
    )
    anchor.gravity:    Edges.Bottom
    anchor.adjustment: PopupAdjustment.None
    Item {
        id:      maskProxy
        x:       root.implicitWidth - sizer.width-root.fw
        y:       -root.fh
        width:   sizer.width
        height:  Math.max(sizer.height, Math.round(Theme.notchHeight * root.localScale))
    }

    color:   "transparent"
    visible: windowVisible
    mask: Region { item: maskProxy }

    Region {
        id: notifBlurReg
        item: hoverContainer
    }

    BackgroundEffect.blurRegion: PrefsService.bgBlur ? notifBlurReg : null

    // ── Visibility gate ───────────────────────────────────────
    // Window stays alive until the close animation finishes.
    property bool windowVisible: false

    Connections {
        target: Popups
        function onNotificationsOpenChanged() {
            if (Popups.notificationsOpen) {
                root.windowVisible = true
            } else {
                closeTimer.restart()
            }
        }

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
                    Popups.notificationsOpen = true
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
                    Popups.notificationsOpen = false
                }
            }
        }
    }

    Timer {
        id:       closeTimer
        interval: root.animDuration + 20
        onTriggered: root.windowVisible = false
    }



    // ── Sizer ─────────────────────────────────────────────────
    // Anchored top-right so it grows leftward + downward from
    // the right notch — mirroring how Dashboard grows from center.
    Item {
        id: hoverContainer
        anchors.top: parent.top
        anchors.right: parent.right
        width: sizer.width
        height: Math.max(sizer.height, Math.round(Theme.notchHeight * root.localScale))

        HoverHandler {
            onHoveredChanged: root.selfHovered = hovered
        }

        Item {
            id:            sizer
            anchors.top:   parent.top
            anchors.right: parent.right
            clip:          true

            TapHandler {
                onTapped: {
                    Popups.notificationsOpen = true
                    Popups.notificationsPinned = true
                }
            }

            // Width: rNotchMinWidth → notificationsWidth  (+ fw for flare region)
            width: Popups.notificationsOpen
            ? Math.round(Theme.notificationsWidth * root.localScale) + root.fw
            : Math.round(Theme.rNotchMinWidth * root.localScale) + root.fw

            // Height: fh (invisible sliver) → full content height
            height: Popups.notificationsOpen
            ? notifList.height + Math.round(Theme.popupPadding * 2 * root.localScale) + root.fh
            : root.fh

            Behavior on width  { NumberAnimation { duration: root.animDuration; easing.type: Anim.inOutCubic} }
            Behavior on height { NumberAnimation { duration: root.animDuration; easing.type: Anim.inOutCubic} }

            // ── Background ─────────────────────────────────────────
            PopupShape {
                anchors.fill: parent
                attachedEdge: "right"
                color:        Theme.background
                radius:       Math.round(Theme.cornerRadius * root.localScale)
                flareWidth:   root.fw
                flareHeight:  root.fh
            }

            // ── Content ────────────────────────────────────────────
            // Inset clear of the flare region.
            // Fades in slowly after expansion, fades out fast on close.
            Item {
                anchors {
                    fill:         parent
                    topMargin:    root.fh + Math.round(4 * root.localScale)
                    leftMargin:   root.fw + Math.round(4 * root.localScale)
                    rightMargin:  Math.round(4 * root.localScale)
                    bottomMargin: Math.round(4 * root.localScale)
                }

                opacity: Popups.notificationsOpen ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Popups.notificationsOpen
                        ? root.animDuration * 0.5
                        : root.animDuration * 0.15
                    }
                }

                NotificationList {
                    id:    notifList
                    localScale: root.localScale
                    width: parent.width
                }
            }
        }
    }
}
