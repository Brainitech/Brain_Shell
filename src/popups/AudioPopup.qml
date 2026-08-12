import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../services"
import "../"

PanelWindow {
    id: root

    required property var anchorWindow
    screen: anchorWindow ? anchorWindow.screen : undefined

    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    readonly property int fw: Math.round(Theme.cornerRadius * root.localScale)
    readonly property int fh: Math.round(Theme.cornerRadius * root.localScale)

    readonly property var pageWidths: ({
        "output": Math.round(200 * root.localScale),
        "input":  Math.round(200 * root.localScale),
        "mixer":  Math.round(300 * root.localScale)
    })

    readonly property int popupHeight: Math.round(340 * root.localScale)
    readonly property int maxWidth: Math.round(300 * root.localScale)
    
    // Animate target width slightly for tab changes
    property real targetWidth: (pageWidths[Popups.audioPage] ?? maxWidth)
    Behavior on targetWidth { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }

    anchors.right: true
    anchors.top:   true
    margins.top:   screen ? Math.round((screen.height - popupHeight) / 2) : 0
    margins.right: Math.round(Theme.borderWidth * root.localScale)

    implicitWidth:  root.maxWidth
    implicitHeight: root.popupHeight

    exclusionMode: ExclusionMode.Ignore
    color:   "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    visible: slide.windowVisible
    mask: Region { item: maskProxy }

    Region {
        id: audioBlurReg
        item: slide
    }

    BackgroundEffect.blurRegion: PrefsService.bgBlur ? audioBlurReg : null

    Item {
        id:      maskProxy
        x:       slide.x + slide.innerX
        y:       slide.y + slide.innerY
        width:   slide.innerWidth
        height:  slide.innerHeight
    }
    
    PopupSlide {
        id: slide
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.targetWidth
        
        edge:             "right"
        open:             Popups.audioOpen
        hoverEnabled:     Popups.audioAllowHover
        triggerHovered:   Popups.audioTriggerHovered
        pinned:           Popups.audioPinned
        onCloseRequested: Popups.audioOpen = false
        onPinRequested: {
            Popups.audioOpen = true
            Popups.audioPinned = true
        }

        Connections {
            target: Popups
            function onAudioOpenChanged() {
                if (!Popups.audioOpen) audioResetTimer.restart()
                else audioControl.page = Popups.audioPage
            }
            function onAudioPageChanged() {
                audioControl.page = Popups.audioPage
            }
        }
        Connections {
            target: slide
            function onWindowVisibleChanged() {
                if (slide.windowVisible && !Popups.audioOpen) {
                    let opt = PrefsService.defaultAudioTab
                    if (opt === "Input") Popups.audioPage = "input"
                    else if (opt === "Mixers") Popups.audioPage = "mixer"
                    else Popups.audioPage = "output"
                }
            }
        }

        Timer {
            id: audioResetTimer
            interval: Anim.transition + 20
            onTriggered: audioControl.reset()
        }

        PopupShape {
            id: bg
            anchors.fill: parent
            attachedEdge: "right"
            color:        Theme.background
            radius:       Math.round(Theme.cornerRadius * root.localScale)
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        AudioControl {
            id: audioControl
            localScale: root.localScale
            fullyOpen: Popups.audioOpen && !slide.sliding

            width: root.targetWidth - Math.round(14 * root.localScale) - root.fw
            height: root.popupHeight - root.fh * 2 - Math.round(12 * root.localScale)
            
            anchors {
                right:        parent.right
                verticalCenter: parent.verticalCenter
                rightMargin:  root.fw - Math.round(4 * root.localScale)
            }
        }
    }
}
