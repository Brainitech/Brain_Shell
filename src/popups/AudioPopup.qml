import QtQuick
import Quickshell
import "../shapes"
import "../components"
import "../services"
import "../"

PopupWindow {
    id: root

    required property var anchorWindow   // right Border PanelWindow

    readonly property int fw: Theme.cornerRadius
    readonly property int fh: Theme.cornerRadius

    // Wide enough for tab col (40) + divider (1) + content (~160) + margins
    readonly property int popupWidth:  260
    readonly property int popupHeight: 340

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

    implicitWidth:  popupWidth
    implicitHeight: popupHeight

    PopupSlide {
        id: slide
        anchors.fill: parent
        edge:            "right"
        open:            Popups.audioOpen
        hoverEnabled:    false
        triggerHovered:  Popups.audioTriggerHovered
        onCloseRequested: Popups.audioOpen = false

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
            anchors {
                fill:         parent
                topMargin:    root.fh + 6
                bottomMargin: root.fh + 6
                leftMargin:   10
                rightMargin:  root.fw + 8
            }
        }
    }
}
