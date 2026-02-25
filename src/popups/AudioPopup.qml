import QtQuick
import Quickshell
import "../shapes"
import "../components"
import "../services"
import "../"

PopupWindow {
    id: root

    required property var anchorWindow

    readonly property int fw: Theme.cornerRadius
    readonly property int fh: Theme.cornerRadius

    // Content width per page — only the inner sizer animates, not the window
    readonly property var pageWidths: ({
        "output": 200,
        "input":  200,
        "mixer":  300
    })

    readonly property int popupHeight: 340

    // Window is FIXED at max width — never animates
    readonly property int maxWidth: 300

    color:   "transparent"
    visible: slide.windowVisible

    anchor.window:  anchorWindow
    anchor.rect: Qt.rect(
        Theme.cornerRadius,
        anchorWindow.height / 2,
        0,
        popupHeight
    )
    anchor.gravity: Edges.Left

    implicitWidth:  maxWidth      // ← fixed, compositor never resizes
    implicitHeight: popupHeight   // ← fixed

    PopupSlide {
        id: slide
        anchors.fill: parent
        edge:             "right"
        open:             Popups.audioOpen
        hoverEnabled:     false
        triggerHovered:   Popups.audioTriggerHovered
        onCloseRequested: Popups.audioOpen = false

        // ── Inner sizer: animates width per page, clips content ───────────────
        Item {
            id: sizer
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            // Width is the only thing that animates — smooth because it's pure QML
            width:  (root.pageWidths[audioControl.page] ?? root.maxWidth)
            height: root.popupHeight

            Behavior on width { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic } }

            PopupShape {
                id: bg
                anchors.fill: parent
                attachedEdge: "right"
                color:        Theme.background
                radius:       Theme.cornerRadius
                flareWidth:   root.fw
                flareHeight:  root.fh
            }

            AudioControl {
                id: audioControl
                anchors {
                    fill:         parent
                    topMargin:    root.fh + 6
                    bottomMargin: root.fh + 6
                    leftMargin:   10
                    rightMargin:  root.fw - 4
                }
            }
        }
    }
}
