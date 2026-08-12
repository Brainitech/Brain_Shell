import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../services"
import "../components"
import "../"

PanelWindow {
    id: root

    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

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

    // Constant size for the panel window
    readonly property int targetWidth: contentWidth + fw
    readonly property int targetHeight: contentHeight + fh * 2

    property string page: "power"

    anchors.left:   true
    anchors.top:    true
    anchors.bottom: true
    margins.top:    screen ? Math.round((screen.height - targetHeight) / 2) : 0
    margins.bottom: screen ? Math.round((screen.height - targetHeight) / 2) : 0
    margins.left:   Math.round(Theme.borderWidth * root.localScale)

    implicitWidth:  targetWidth
    implicitHeight: targetHeight

    exclusionMode: ExclusionMode.Ignore
    color:         "transparent"
    WlrLayershell.layer: WlrLayer.Overlay

    visible: slide.windowVisible
    mask: Region { item: maskProxy }

    Region {
        id: archBlurReg
        item: slide
    }

    BackgroundEffect.blurRegion: PrefsService.bgBlur ? archBlurReg : null

    Item {
        id:      maskProxy
        x:       slide.x + slide.innerX
        y:       slide.y + slide.innerY
        width:   slide.innerWidth
        height:  slide.innerHeight
    }

    PopupSlide {
        id: slide
        anchors.fill: parent
        edge:             "left"
        hoverEnabled:     Popups.archMenuAllowHover
        triggerHovered:   Popups.archMenuTriggerHovered
        pinned:           Popups.archMenuPinned
        open:             Popups.archMenuOpen
        onCloseRequested: Popups.archMenuOpen = false
        onPinRequested: {
            Popups.archMenuOpen = true
            Popups.archMenuPinned = true
        }

        PopupShape {
            id: bg
            anchors.fill: parent
            attachedEdge: "left"
            color:        Theme.background
            radius:       Math.round(Theme.cornerRadius * root.localScale)
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        Item {
            anchors {
                fill:         parent
                leftMargin:   root.fw - Math.round(4 * root.localScale)
                rightMargin:  Math.round(8 * root.localScale)
                topMargin:    root.fh + Math.round(6 * root.localScale)
                bottomMargin: root.fh + Math.round(6 * root.localScale)
            }
            
            //── Page content ──────────────────────────────────────────
            Item {
                width:  root.contentWidth - Math.round(12 * root.localScale)
                height: root.contentHeight - Math.round(12 * root.localScale)
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
