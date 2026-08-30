import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../"

Item {
    id: root

    property real localScale: 1.0

    readonly property int popupWidth:  Math.round(420 * root.localScale)
    readonly property int popupHeight: Math.round(560 * root.localScale)
    readonly property int fw: Math.round(Theme.cornerRadius * root.localScale)
    readonly property int fh: Math.round(Theme.cornerRadius * root.localScale)




    Connections {
        target: Popups
        function onClipboardTriggerHoveredChanged() {
            if (Popups.clipboardTriggerHovered) {
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

    property bool allowHover: Popups.clipboardAllowHover
    property bool pinned:     Popups.clipboardPinned
    property bool selfHovered: false

    onSelfHoveredChanged: {
        if (root.allowHover) {
            if (!selfHovered && !Popups.clipboardTriggerHovered) hoverCloseTimer.restart()
            else                                                 hoverCloseTimer.stop()
        }
    }

    Timer {
        id: hoverOpenTimer
        interval: Popups.hoverOpenDelay
        onTriggered: {
            if (root.allowHover && Popups.clipboardTriggerHovered) {
                if (!Popups.clipboardOpen) {
                    Popups.closeAll()
                    SurfaceState.open("bottomRight", "clipboard")
                }
            }
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: Popups.hoverCloseDelay
        onTriggered: {
            if (root.allowHover && !Popups.clipboardTriggerHovered && !root.selfHovered) {
                if (!root.pinned) {
                    SurfaceState.close()
                }
            }
        }
    }

    

    // ── Content ────────────────────────────────────────────
    Item {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.popupWidth
        height: root.popupHeight

        HoverHandler {
            onHoveredChanged: root.selfHovered = hovered
        }

        Item {
            anchors.fill: parent

            opacity: Popups.clipboardOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic } }

            TapHandler {
                onTapped: {
                    SurfaceState.open("bottomRight", "clipboard")
                    Popups.clipboardPinned = true
                }
            }

            HistoryTab {
                anchors.fill: parent
                anchors.margins: Math.round(8 * root.localScale)
                localScale: root.localScale
            }
        }
    }
}