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

    Region {
        id: clipBlurReg
        item: sizer
    }

    BackgroundEffect.blurRegion: PrefsService.bgBlur ? clipBlurReg : null

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
                    Popups.clipboardOpen = true
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
                    Popups.clipboardOpen = false
                }
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Anim.transition + 20
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
        id: hoverContainer
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        width:  sizer.width  + Theme.borderWidth
        height: sizer.height + Theme.borderWidth

        HoverHandler {
            onHoveredChanged: root.selfHovered = hovered
        }

        Item {
            id: sizer
            anchors.top:  parent.top
            anchors.left: parent.left
            clip: true

            width:  Popups.clipboardOpen ? root.popupWidth  + root.fw : 0
            height: Popups.clipboardOpen ? root.popupHeight + root.fh : 0

            Behavior on width  { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }
            Behavior on height { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }

            TapHandler {
                onTapped: {
                    Popups.clipboardOpen = true
                    Popups.clipboardPinned = true
                }
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
                    right:        parent.right
                    bottom:       parent.bottom
                    bottomMargin: Math.round(8 * root.localScale)
                }
                width:  root.popupWidth  - Math.round(10 * root.localScale)
                height: root.popupHeight - Math.round(16 * root.localScale)

            opacity: Popups.clipboardOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Popups.clipboardOpen ? Anim.transition * 0.5 : Anim.transition * 0.15
                }
            }

            HistoryTab { 
                anchors.fill: parent
                localScale: root.localScale
            }
        }
    }
}


}
