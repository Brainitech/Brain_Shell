import QtQuick
import Quickshell
import Quickshell.Io
import "../shapes"
import "../services"
import "../components"
import "../"
import "../theme"

PopupWindow {
	id: root

	required property var anchorWindow

	readonly property int fw: Theme.cornerRadius
	readonly property int fh: Theme.cornerRadius

	readonly property var pageHeights: ({
		"power":       270,
		"performance": 190,
		"stats":       250
	})
	readonly property var pageWidths: ({
		"power":       220,
		"performance": 260,
		"stats":       390
	})

	readonly property int contentWidth:  pageWidths[page]  ?? 220
	readonly property int contentHeight: pageHeights[page] ?? 220

	property string page: "power"

	color:   "transparent"
	visible: slide.windowVisible
	mask: Region { item: maskProxy }

	implicitWidth:  (pageWidths["stats"]  ?? 220) + fw
	implicitHeight: (pageHeights["stats"] ?? 220) + fh * 2

	anchor.window:  anchorWindow
	anchor.gravity: Edges.Right
	anchor.rect: Qt.rect(
		0,
		anchorWindow.height / 2,
		anchorWindow.width,
		implicitHeight
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
		hoverEnabled:     false
		triggerHovered:   Popups.archMenuTriggerHovered
		open:             Popups.archMenuOpen
		onCloseRequested: Popups.archMenuOpen = false

		Item {
			id: sizer
			anchors.left:           parent.left
			anchors.verticalCenter: parent.verticalCenter
			clip: true

			width:  root.contentWidth  + root.fw
			height: root.contentHeight + root.fh * 2

Behavior on width  { NumberAnimation { duration: Anim.standardNormal; easing: Anim.outBack } }
                     Behavior on height { NumberAnimation { duration: Anim.standardNormal; easing: Anim.outBack } }

			PopupShape {
				id: bg
				anchors.fill: parent
				attachedEdge: "left"
				color:        Theme.background
				radius:       Theme.cornerRadius
				flareWidth:   root.fw
				flareHeight:  root.fh
			}

			ShellPopupBase {
				id: content
				anchors {
					fill:         parent
					leftMargin:   root.fw - 4
					rightMargin:  8
					topMargin:    root.fh + 6
					bottomMargin: root.fh + 6
				}
				isOpen: Popups.archMenuOpen
				transformEdge: "left"
				disableAutoHide: true

				Item {
				width:  parent.width
					height: parent.height
					clip:   true
											PopupPage {
					anchors.fill: parent
						visible: root.page === "power"
													PowerMenu {
						width: parent.width
							}
						}
				}
			}
		}
	}
}