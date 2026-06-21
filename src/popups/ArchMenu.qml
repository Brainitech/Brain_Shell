import QtQuick
import Quickshell
import Quickshell.Io
import "../shapes"
import "../services"
import "../components"
import "../"

PopupWindow {
	id: root

	required property var anchorWindow

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

	property string page: "power"

	color:   "transparent"
	visible: slide.windowVisible
	mask: Region { item: maskProxy }

	implicitWidth:  (pageWidths["stats"]  ?? Math.round(220 * root.localScale)) + fw
	implicitHeight: (pageHeights["stats"] ?? Math.round(220 * root.localScale)) + fh * 2

	anchor.window:  anchorWindow
	anchor.gravity: Edges.Right
	anchor.rect: Qt.rect(
		0,
		anchorWindow.height / 2,
		anchorWindow.width,
		anchorWindow.height
	)

	Item {
		id:      maskProxy
		x:       0
		y:       (root.implicitHeight - sizer.height) / 2-root.fh
		width:   sizer.width
		height:  sizer.height
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

		Item {
			id: sizer
			anchors.left:           parent.left
			anchors.verticalCenter: parent.verticalCenter
			clip: true

			width:  root.contentWidth  + root.fw
			height: root.contentHeight + root.fh * 2

			Behavior on width  { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }
			Behavior on height { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }

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
						width:  parent.width
						height: parent.height
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
}
