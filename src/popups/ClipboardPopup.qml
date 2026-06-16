import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../"

PanelWindow {
    id: root

    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    readonly property int popupWidth:  Math.round(420 * root.localScale)
    readonly property int popupHeight: Math.round(560 * root.localScale)
    readonly property int fw: Math.round(Theme.cornerRadius * root.localScale)
    readonly property int fh: Math.round(Theme.cornerRadius * root.localScale)

    anchors.top:    true
    anchors.left:   true
    anchors.right:  true
    anchors.bottom: true

    exclusionMode: ExclusionMode.Ignore
    color:         "transparent"

    WlrLayershell.layer:         WlrLayer.Overlay
    property bool wantsFocus: false
    WlrLayershell.keyboardFocus: wantsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Timer {
        id: focusGrabTimer
        interval: 15
        onTriggered: { if (root.windowVisible && Popups.clipboardOpen) root.wantsFocus = true }
    }

    property bool windowVisible: false
    visible: windowVisible

    Connections {
        target: Popups
        function onClipboardOpenChanged() {
            if (Popups.clipboardOpen) {
                closeTimer.stop()
                root.windowVisible = true
                focusGrabTimer.restart()
            } else {
                root.wantsFocus = false
                focusGrabTimer.stop()
                closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Theme.animDuration + 20
        onTriggered: {
            if (!Popups.clipboardOpen)
                root.windowVisible = false
        }
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked:    Popups.clipboardOpen = false
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

        Behavior on width  { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic } }
        Behavior on height { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked:    {}
        }

        PopupShape {
            anchors.fill: parent
            attachedEdge: "bottom-right"
            color:        Theme.background
            radius:       Math.round(Theme.cornerRadius * root.localScale)
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        Item {
            id: content
            anchors {
                fill:         parent
                topMargin:    root.fh + Math.round(8 * root.localScale)
                leftMargin:   root.fw + Math.round(10 * root.localScale)
                bottomMargin: Math.round(8 * root.localScale)
            }

            opacity: Popups.clipboardOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Popups.clipboardOpen ? Theme.animDuration * 0.5 : Theme.animDuration * 0.15
                }
            }

            HistoryTab { 
                anchors.fill: parent
                localScale: root.localScale
            }
        }
    }
}
