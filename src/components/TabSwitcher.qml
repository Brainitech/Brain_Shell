import QtQuick
import "../"

// Unified tab switcher — horizontal or vertical.
//
// orientation: "horizontal" (default) — Row, fills parent width, tabs spaced equally
//              "vertical"             — Column, fills parent height, tabs spaced equally
//
// Horizontal: icon + label pill, bottom divider. Used by Dashboard.
// Vertical:   icon-only solid pill. Used by ArchMenu.
//
// Model: [{ key: string, icon: string, label?: string }]
// label is optional — only rendered in horizontal orientation.
//
// Sizing contract:
//   Horizontal — parent MUST set width.  implicitHeight is 40.
//   Vertical   — parent MUST set height. implicitWidth  is 40.

Item {
	id: root

	property var    model:       []
	property string currentPage: ""
	property string orientation: "horizontal"   // "horizontal" | "vertical"
	property real   localScale:  1.0

	signal pageChanged(string key)

	// ── Default page & reset ──────────────────────────────────────────────────
	// defaultPage auto-resolves to the first model entry.
	// Call reset() from the popup's close handler to restore it off-screen.
	property string defaultPage: model.length > 0 ? model[0].key : ""

	function reset() {
		pageChanged(defaultPage)
	}

	implicitWidth:  orientation === "vertical"   ? Math.round(40 * localScale) : 0
	implicitHeight: orientation === "horizontal" ? Math.round(40 * localScale) : 0

	// ── Scroll cooldown ───────────────────────────────────────────────────────
	property bool scrollBusy: false

	Timer {
		id: scrollCooldown
		interval: 300
		repeat:   false
		onTriggered: root.scrollBusy = false
	}

	WheelHandler {
		acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
		onWheel: function(event) {
			if (root.scrollBusy) return
			root.scrollBusy = true
			scrollCooldown.restart()
			var keys = root.model.map(function(m) { return m.key })
			var idx  = keys.indexOf(root.currentPage)
			if (event.angleDelta.y < 0)
			idx = (idx + 1) % keys.length
			else
			idx = (idx - 1 + keys.length) % keys.length
			root.pageChanged(keys[idx])
		}
	}

	// ── HORIZONTAL layout — Row ───────────────────────────────────────────────
	Item {
		id: hContainer
		anchors.fill: parent
		visible: root.orientation === "horizontal"

		Rectangle {
			id: hMorph
			property int activeIdx: {
				for (var i = 0; i < root.model.length; ++i) {
					if (root.model[i].key === root.currentPage) return i;
				}
				return 0;
			}
			
			property Item activeTab: hRepeater.count > 0 ? hRepeater.itemAt(activeIdx) : null
			property real targetWidth: activeTab ? activeTab.bgWidth : 0
			
			// isReady prevents animations until the item has rendered its first real width
			property bool isReady: hMorph.width > 0

			property real animIdx: activeIdx
			Behavior on animIdx {
				enabled: hMorph.isReady
				NumberAnimation { duration: 350; easing.type: Easing.OutExpo }
			}

			property real animWidth: targetWidth
			Behavior on animWidth {
				enabled: hMorph.isReady
				NumberAnimation { duration: 350; easing.type: Easing.OutExpo }
			}

			height: parent.height - Math.round(8 * localScale)
			y: Math.round(4 * localScale)
			radius: height / 2
			color: Theme.active

			width: animWidth
			
			property real slotWidth: root.model.length > 0 ? hRow.width / root.model.length : 0
			x: slotWidth > 0 ? (animIdx * slotWidth) + (slotWidth - animWidth) / 2 : 0
		}

		Row {
			id: hRow
			anchors.fill: parent

			Repeater {
				id: hRepeater
				model: root.orientation === "horizontal" ? root.model : []

				delegate: Item {
					id: hTab
					readonly property bool isActive: root.currentPage === modelData.key
					readonly property real bgWidth: hIcon.implicitWidth + (modelData.label !== undefined ? hLabel.implicitWidth : 0) + Math.round(24 * localScale)

					width:  hRow.width / root.model.length
					height: hRow.height

					// Hover background
					Rectangle {
						id: hHoverBg
						anchors.centerIn: parent
						width: hTab.bgWidth
						height: parent.height - Math.round(8 * localScale)
						radius: height / 2
						color: !hTab.isActive && hHov.hovered ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
						Behavior on color { ColorAnimation { duration: 120 } }
					}

					// Icon + label
					Row {
						anchors.centerIn: parent
						spacing: Math.round(6 * localScale)

						Text {
							id: hIcon
							text:           modelData.icon
							font.pixelSize: Math.round(14 * localScale)
							anchors.verticalCenter: parent.verticalCenter
							color: hTab.isActive
							? Theme.background
							: (hHov.hovered ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(1, 1, 1, 0.4))
							Behavior on color { ColorAnimation { duration: 120 } }
						}

						Text {
							id: hLabel
							visible:        modelData.label !== undefined
							text:           modelData.label ?? ""
							font.pixelSize: Math.round(12 * localScale)
							font.weight:    hTab.isActive ? Font.Medium : Font.Normal
							anchors.verticalCenter: parent.verticalCenter
							color: hTab.isActive
							? Theme.background
							: (hHov.hovered ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(1, 1, 1, 0.4))
							Behavior on color { ColorAnimation { duration: 120 } }
						}
					}

					HoverHandler { id: hHov; cursorShape: Qt.PointingHandCursor }
					MouseArea {
						anchors.fill: parent
						onClicked:    root.pageChanged(modelData.key)
					}
				}
			}
		}
	}

	// Bottom divider — horizontal only
	Rectangle {
		visible:        root.orientation === "horizontal"
		anchors.bottom: parent.bottom
		anchors.left:   parent.left
		anchors.right:  parent.right
		height:         1
		color:          Qt.rgba(1, 1, 1, 0.07)
	}

	// ── VERTICAL layout — Column ──────────────────────────────────────────────
	    Item {
	        id: vContainer
	        anchors.centerIn: parent
	        visible: root.orientation === "vertical"
	        width:   root.width
			height:  root.height
	
	        readonly property int tabH: Math.round(60 * localScale)
	        readonly property real vSpacing: root.model.length > 1
	            ? (root.height - root.model.length * tabH) / (root.model.length - 1)
	            : 0
	
	        readonly property bool hasLabels:
	            root.model.length > 0 &&
	            root.model[0].label !== undefined &&
	            root.model[0].label !== ""

			Rectangle {
				id: vMorph
				width: parent.width
				height: vContainer.tabH
				radius: Math.round(Theme.cornerRadius * 2 * localScale)
				color: Theme.active

				property int activeIdx: {
					for (var i = 0; i < root.model.length; ++i) {
						if (root.model[i].key === root.currentPage) return i;
					}
					return 0;
				}
				
				property bool isReady: vContainer.height > 0
				property real animIdx: activeIdx
				
				Behavior on animIdx {
					enabled: vMorph.isReady
					NumberAnimation { duration: 350; easing.type: Easing.OutExpo }
				}

				y: animIdx * (vContainer.tabH + vContainer.vSpacing)
			}
	
			Column {
				id: vCol
				anchors.fill: parent
				spacing: vContainer.vSpacing

				Repeater {
					id: vRepeater
					model: root.orientation === "vertical" ? root.model : []
		
					delegate: Item {
						id: vTab
						readonly property bool isActive: root.currentPage === modelData.key
		
						width:  vCol.width
						height: vContainer.tabH

						// Hover background
						Rectangle {
							anchors.fill: parent
							radius: Math.round(Theme.cornerRadius * 2 * localScale)
							color: !vTab.isActive && vHov.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
							Behavior on color { ColorAnimation { duration: 120 } }
						}
		
						// Icon-only (no label)
						Text {
							visible:          !vContainer.hasLabels
							anchors.centerIn: parent
							text:             modelData.icon
							font.pixelSize:   Math.round(16 * localScale)
							color: vTab.isActive ? Theme.background : Theme.text
							Behavior on color { ColorAnimation { duration: 120 } }
						}
		
						// Icon + label row
						Row {
							visible: vContainer.hasLabels
							anchors {
								left:           parent.left
								leftMargin:     Math.round(16 * localScale)
								verticalCenter: parent.verticalCenter
							}
							spacing: Math.round(12 * localScale)
		
							Text {
								text:           modelData.icon
								font.pixelSize: Math.round(15 * localScale)
								anchors.verticalCenter: parent.verticalCenter
								color: vTab.isActive
									? Theme.background
									: (vHov.hovered ? Qt.rgba(1, 1, 1, 0.80) : Qt.rgba(1, 1, 1, 0.42))
								Behavior on color { ColorAnimation { duration: 120 } }
							}
		
							Text {
								text:           modelData.label ?? ""
								font.pixelSize: Math.round(12 * localScale)
								font.weight:    vTab.isActive ? Font.Medium : Font.Normal
								anchors.verticalCenter: parent.verticalCenter
								color: vTab.isActive
									? Theme.background
									: (vHov.hovered ? Qt.rgba(1, 1, 1, 0.80) : Qt.rgba(1, 1, 1, 0.42))
								Behavior on color { ColorAnimation { duration: 120 } }
							}
						}
		
						HoverHandler { id: vHov; cursorShape: Qt.PointingHandCursor }
						MouseArea {
							anchors.fill: parent
							onClicked:    root.pageChanged(modelData.key)
						}
					}
				}
			}
	    }
	}

