import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../"
import "../theme"

PanelWindow {
    id: root

    readonly property int popupWidth:  420
    readonly property int popupHeight: 560
    readonly property int fw: Theme.cornerRadius
    readonly property int fh: Theme.cornerRadius

    anchors.right:  true
    anchors.bottom: true

    implicitWidth:  popupWidth  + fw
    implicitHeight: popupHeight + fh

    exclusionMode: ExclusionMode.Ignore
    color:         "transparent"

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    mask: Region { item: maskProxy }
    Item {
        id: maskProxy
        x:      root.implicitWidth  - sizer.width
        y:      root.implicitHeight - sizer.height
        width:  sizer.width
        height: sizer.height
    }

    property bool windowVisible: false
    visible: windowVisible

    Connections {
        target: Popups
        function onClipboardOpenChanged() {
            if (Popups.clipboardOpen) {
                closeTimer.stop()
                root.windowVisible = true
            } else {
                closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Anim.standardNormal + 20
        onTriggered: {
            if (!Popups.clipboardOpen)
                root.windowVisible = false
        }
    }
    
    Item {
        id: sizer
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Theme.borderWidth
        anchors.bottomMargin: Theme.borderWidth
        clip: true

        width:  Popups.clipboardOpen ? root.popupWidth  + root.fw : 0
        height: Popups.clipboardOpen ? root.popupHeight + root.fh : 0

        Behavior on width  { NumberAnimation { duration: Anim.standardNormal; easing.type: Anim.easing("standard").type; easing.bezierCurve: Anim.easing("standard").bezierCurve } }
        Behavior on height { NumberAnimation { duration: Anim.standardNormal; easing.type: Anim.easing("standard").type; easing.bezierCurve: Anim.easing("standard").bezierCurve } }

        PopupShape {
            anchors.fill: parent
            attachedEdge: "bottom-right"
            color:        Theme.background
            radius:       Theme.cornerRadius
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        Item {
            id: content
            anchors {
                fill:         parent
                topMargin:    root.fh + 8
                leftMargin:   root.fw + 10
                bottomMargin: 8
            }

            opacity: Popups.clipboardOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Popups.clipboardOpen ? Math.round(Anim.standardNormal * 0.5) : Math.round(Anim.standardNormal * 0.15)
                    easing.type: Anim.easing("standard").type
                    easing.bezierCurve: Anim.easing("standard").bezierCurve
                }
            }

            HistoryTab { anchors.fill: parent }
        }
    }
}
