import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../services"
import "../"

Item {
    id: root

    property real localScale: 1.0

    readonly property int popupHeight: Math.round(340 * root.localScale)
    readonly property int maxWidth: Math.round(300 * root.localScale)

    readonly property var pageWidths: ({
        "output": Math.round(200 * root.localScale),
        "input":  Math.round(200 * root.localScale),
        "mixer":  Math.round(300 * root.localScale)
    })
    
    // Animate target width slightly for tab changes
    property real targetWidth: (pageWidths[Popups.audioPage] ?? maxWidth)

    readonly property int popupWidth: targetWidth

    onOpacityChanged: if (opacity === 1) forceActiveFocus()
    Keys.onEscapePressed: SurfaceState.close()

    MouseArea {
        anchors.fill: parent
        onClicked: Popups.audioPinned = true
    }
    
    property bool selfHovered: false

    Item {
        id: slide
        anchors.fill: parent
        clip: true

        HoverHandler {
            onHoveredChanged: {
                if (Popups.audioAllowHover) {
                    root.selfHovered = hovered
                    if (hovered) {
                        hoverCloseTimer.stop()
                    } else if (!Popups.audioTriggerHovered) {
                        hoverCloseTimer.restart()
                    }
                }
            }
        }

        Timer {
            id: hoverCloseTimer
            interval: Popups.hoverCloseDelay
            onTriggered: {
                if (Popups.audioAllowHover && !Popups.audioPinned) {
                    if (Popups.audioOpen) SurfaceState.close()
                }
            }
        }

        Connections {
            target: Popups
            function onAudioOpenChanged() {
                if (!Popups.audioOpen) {
                    audioResetTimer.restart()
                    hoverOpenTimer.stop()
                    if (Popups.audioAllowHover && !root.selfHovered) hoverCloseTimer.restart()
                } else {
                    audioControl.page = Popups.audioPage
                    hoverCloseTimer.stop()
                }
            }
            function onAudioPageChanged() {
                audioControl.page = Popups.audioPage
            }
            function onAudioTriggerHoveredChanged() {
                if (Popups.audioTriggerHovered) {
                    if (Popups.audioAllowHover) {
                        hoverCloseTimer.stop()
                        hoverOpenTimer.restart()
                    }
                } else {
                    hoverOpenTimer.stop()
                    if (Popups.audioAllowHover && !root.selfHovered) hoverCloseTimer.restart()
                }
            }
        }

        Timer {
            id: hoverOpenTimer
            interval: Popups.hoverOpenDelay
            onTriggered: {
                if (Popups.audioAllowHover && Popups.audioTriggerHovered) {
                    if (!Popups.audioOpen) {
                        SurfaceState.open("rightCenter", "audio")
                    }
                }
            }
        }

        onOpacityChanged: {
            if (opacity === 1 && !Popups.audioOpen) {
                let opt = PrefsService.defaultAudioTab
                if (opt === "Input") Popups.audioPage = "input"
                else if (opt === "Mixers") Popups.audioPage = "mixer"
                else Popups.audioPage = "output"
            }
        }

        Timer {
            id: audioResetTimer
            interval: Anim.transition + 20
            onTriggered: audioControl.reset()
        }

        AudioControl {
            id: audioControl
            localScale: root.localScale
            fullyOpen: Popups.audioOpen && root.opacity === 1

            width: root.targetWidth - Math.round(16 * root.localScale)
            height: root.popupHeight - Math.round(16 * root.localScale)
            
            anchors.centerIn: parent
        }
    }
}
