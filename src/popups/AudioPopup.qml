import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../services"
import "../"

PopupWindow {
	id: root

	required property var anchorWindow

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

	color:   "transparent"
	visible: slide.windowVisible
	mask: Region { item: maskProxy }

	Region {
		id: audioBlurReg
		item: sizer
	}

	BackgroundEffect.blurRegion: PrefsService.bgBlur ? audioBlurReg : null

	anchor.window:  anchorWindow
	anchor.rect: Qt.rect(
		Math.round(Theme.cornerRadius * root.localScale),
		anchorWindow ? anchorWindow.height/2 : 0,
		0,
		popupHeight
	)
	anchor.gravity: Edges.Left
	
	Item {
	    id:      maskProxy
	    x:       root.maxWidth - sizer.width
	    y:       ((root.popupHeight - sizer.height) / 2) -root.fh
	    width:   sizer.width
	    height:  sizer.height
	}

	implicitWidth:  maxWidth
	implicitHeight: popupHeight
	
	PopupSlide {
		id: slide
		anchors.fill: parent
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

		Item {
			id: sizer
			anchors.right:          parent.right
			anchors.verticalCenter: parent.verticalCenter
			clip: true

			width:  (root.pageWidths[audioControl.page] ?? root.maxWidth)
			height: root.popupHeight

			Behavior on width { id: sizerWidthAnim; NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }

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
				fullyOpen: Popups.audioOpen && !slide.sliding && Math.round(sizer.width) === Math.round(root.pageWidths[audioControl.page] ?? root.maxWidth)
				anchors {
					fill:         parent
					topMargin:    root.fh + Math.round(6 * root.localScale)
					bottomMargin: root.fh + Math.round(6 * root.localScale)
					leftMargin:   Math.round(10 * root.localScale)
					rightMargin:  root.fw - Math.round(4 * root.localScale)
				}
			}
		}
	}
}
