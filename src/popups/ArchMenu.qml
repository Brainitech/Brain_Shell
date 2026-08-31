import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../services"
import "../components"
import "../"

Item {
    id: root

    property real localScale: 1.0

    readonly property int fw: Math.round(Theme.cornerRadius * root.localScale)
    readonly property int fh: Math.round(Theme.cornerRadius * root.localScale)

    readonly property var pageHeights: ({
        "power":       Math.round(270 * root.localScale),
        "performance": Math.round(190 * root.localScale),
        "stats":       Math.round(250 * root.localScale)
    })
    readonly property var pageWidths: ({
        "power":       Math.round(220 * root.localScale),
        "performance": Math.round(260 * root.localScale),
        "stats":       Math.round(390 * root.localScale)
    })

    readonly property int contentWidth:  pageWidths[page]  ?? Math.round(220 * root.localScale)
    readonly property int contentHeight: pageHeights[page] ?? Math.round(220 * root.localScale)

    readonly property int targetWidth: contentWidth
    readonly property int targetHeight: contentHeight
    readonly property int popupWidth: targetWidth
    readonly property int popupHeight: targetHeight

    property string page: "power"
    property bool selfHovered: false

    onOpacityChanged: if (opacity === 1) forceActiveFocus()
    Keys.onEscapePressed: SurfaceState.close()
    MouseArea {
        anchors.fill: parent
        onClicked: Popups.archMenuPinned = true
    }

    Item {
        id: slide
        anchors.fill: parent

        HoverHandler {
            onHoveredChanged: {
                root.selfHovered = hovered
                if (Popups.archMenuAllowHover) {
                    if (hovered) {
                        hoverCloseTimer.stop()
                    } else if (!Popups.archMenuTriggerHovered) {
                        hoverCloseTimer.restart()
                    }
                }
            }
        }

        Connections {
            target: Popups
            function onArchMenuTriggerHoveredChanged() {
                if (Popups.archMenuTriggerHovered) {
                    if (Popups.archMenuAllowHover) {
                        hoverCloseTimer.stop()
                        hoverOpenTimer.restart()
                    }
                } else {
                    hoverOpenTimer.stop()
                    if (Popups.archMenuAllowHover && !root.selfHovered) hoverCloseTimer.restart()
                }
            }
        }

        Timer {
            id: hoverOpenTimer
            interval: Popups.hoverOpenDelay
            onTriggered: {
                if (Popups.archMenuAllowHover && Popups.archMenuTriggerHovered) {
                    if (!Popups.archMenuOpen) {
                        Popups.closeAll()
                        SurfaceState.open("leftCenter", "archMenu")
                    }
                }
            }
        }

        Timer {
            id: hoverCloseTimer
            interval: Popups.hoverCloseDelay
            onTriggered: {
                if (Popups.archMenuAllowHover && !Popups.archMenuPinned) {
                    SurfaceState.close()
                }
            }
        }

        Item {
            anchors {
                fill:         parent
                leftMargin:   Math.round(8 * root.localScale)
                rightMargin:  Math.round(8 * root.localScale)
                topMargin:    Math.round(8 * root.localScale)
                bottomMargin: Math.round(8 * root.localScale)
            }
            
            //── Page content ──────────────────────────────────────────
            Item {
                anchors.centerIn: parent
                width:  root.contentWidth - Math.round(16 * root.localScale)
                height: root.contentHeight - Math.round(16 * root.localScale)
                clip:   true

                PopupPage {
                    anchors.fill: parent
                    visible: root.page === "power"

                    PowerMenu {
                        localScale: root.localScale
                        width: parent.width
                    }
                }
            }
        }
    }
}
