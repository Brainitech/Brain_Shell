import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../services/"
import "../"

Item {
    id: root
    property real localScale: 1.0

        
    readonly property int toastWidth: Math.round(Theme.notificationToastWidth * localScale) + Math.round(10 * localScale)


	property bool showing:       false
	property var  current:       null
	property var  queue:         []

	Connections {
		target: SurfaceState
		function _handleInterrupt() {
			if ((SurfaceState.activeContent === "notifications") || (SurfaceState.activeContent === "network")) {
				root.queue = []
				if (root.showing || root.current) {
					autoTimer.stop()
					root.showing = false
					Popups.notificationToastOpen = false
					root.current = null
				}
			}
		}
		function onActiveContentChanged() {
			_handleInterrupt()
		}
	}

	Connections {
		target: NotificationService
		function onNotificationAdded(n) {
			if (!n || !n.tracked) return
			if ((SurfaceState.activeContent === "notifications") || (SurfaceState.activeContent === "network")) return
			if (root.current === null) {
				root.startShow(n)
			} else {
				root.queue = [...root.queue, n]
			}
		}
	}

	function startShow(n) {
		root.current       = n
		root.showing       = false
		
		slideInTimer.restart()
		Popups.notificationToastOpen = false
	}

	function startDismiss() {
		autoTimer.stop()
		root.showing = false
		Popups.notificationToastOpen = false
		slideOutTimer.restart()
	}

	Connections {
		target:               root.current
		ignoreUnknownSignals: true
		function onClosed() { root.startDismiss() }
	}

	Timer {
		id:          slideInTimer
		interval:    30
		onTriggered: { root.showing = true; Popups.notificationToastOpen = true; autoTimer.restart() }
	}

	NumberAnimation {
		id:          autoTimer
		target:      progressBar
		property:    "width"
		from:        root.toastWidth - Math.round(10 * root.localScale)
		to:          0
		duration:    5000
		easing.type: Anim.linear
		onFinished:  root.startDismiss()
	}

	Timer {
		id:       slideOutTimer
		interval: Anim.transition + 20
		onTriggered: {
			if (root.queue.length > 0) {
				const next = root.queue[0]
				root.queue = root.queue.slice(1)
				root.startShow(next)
			} else {
				root.current       = null
			}
		}
	}

	// ── Card ───────────────────────────────────────────────────
	property int targetHeight: root.showing ? (cardCol.y + cardCol.implicitHeight + Math.round(24 * root.localScale) ) : 0

	Item {
		id:            card
		anchors.fill:  parent
		clip:          true

		TapHandler {
			acceptedButtons: Qt.RightButton | Qt.MiddleButton
			onTapped: root.startDismiss()
		}

		TapHandler {
			acceptedButtons: Qt.LeftButton
			onTapped: {
				if (root.current) {
					if (typeof root.current.invokeDefaultAction === "function") root.current.invokeDefaultAction()
					else if (typeof root.current.invokeDefault === "function") root.current.invokeDefault()
					else if (root.current.actions) {
						for (var i = 0; i < root.current.actions.length; i++) {
							if (root.current.actions[i].id === "default") {
								root.current.actions[i].invoke()
								break
							}
						}
					}
				}
				root.startDismiss()
			}
		}


		Rectangle {
			anchors {
				right:        parent.right
				top:          parent.top
				bottom:       parent.bottom
				topMargin:    0
				bottomMargin: 0
				rightMargin:  0
			}
			width:  Math.round(3 * root.localScale)
			radius: Math.round(2 * root.localScale)
			color: {
				if (!root.current) return "#ABB2BF"
				switch (root.current.urgency) {
					case NotificationUrgency.Critical: return "#e06c75"
					case NotificationUrgency.Low:      return Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.25)
					default:                           return "#ABB2BF"
				}
			}
		}

		Item {
			anchors.fill: parent
			opacity: root.showing ? 1 : 0
			Behavior on opacity { NumberAnimation { duration: Anim.mediumFast} }
			Rectangle {
				id: progressBar
				anchors {
					right:       parent.right
					rightMargin: 0
					bottom:      cardCol.bottom
					bottomMargin: Math.round(-10 * root.localScale)
				}
				height:  Math.round(2 * root.localScale)
				radius:  Math.round(1 * root.localScale)
				color:   Theme.active
				opacity: 0.5
			}

			Column {
				id: cardCol
				anchors {
					left:       parent.left;  leftMargin:  Math.round(14 * root.localScale)
					right:      parent.right; rightMargin: Math.round(14 * root.localScale)

				}
				spacing: Math.round(2 * root.localScale)
				bottomPadding: Math.round(10 * root.localScale)
				y: 0 + Math.round(6 * root.localScale)
				// No fixed height — sizes to content

				Row {
					id:      headerRow
					width:   parent.width
					height: Math.round(40 * root.localScale)
					spacing: Math.round(8 * root.localScale)

					Item {
						width:  Math.round(16 * root.localScale)
						height: Math.round(16 * root.localScale)
						anchors.verticalCenter: parent.verticalCenter

						Image {
							id:           toastIcon
							anchors.fill: parent
							source: {
								var ic = root.current?.appIcon ?? ""
								if (ic === "") return ""
								if (ic.startsWith("/")) return "file://" + ic
								if (!Quickshell.hasThemeIcon(ic)) return ""
								return "image://icon/" + ic
							}
							fillMode:          Image.PreserveAspectFit
							smooth:            true
							visible:           status === Image.Ready
							sourceSize.width:  Math.round(16 * root.localScale) | 0
							sourceSize.height: Math.round(16 * root.localScale) | 0
						}
						Rectangle {
							anchors.fill: parent
							radius:       width / 2
							color:        Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.1)
							visible:      toastIcon.status !== Image.Ready
							Text {
								anchors.centerIn: parent
								text:           (root.current?.appName ?? "?").charAt(0).toUpperCase()
								color:          Theme.text
								font.pixelSize: Math.round(9 * root.localScale) | 0
								font.bold:      true
							}
						}
					}

					Text {
						width:                  parent.width - Math.round(16 * root.localScale) - Math.round(24 * root.localScale) - parent.spacing * 2
						anchors.verticalCenter: parent.verticalCenter
						text:                   root.current?.appName ?? ""
						color:                  Theme.subtext
						font.pixelSize:         Math.round(11 * root.localScale) | 0
						elide:                  Text.ElideRight
					}
				}

				Text {
					width:            parent.width
					text:             root.current?.summary ?? ""
					color:            Theme.text
					font.pixelSize:   Math.round(13 * root.localScale) | 0
					font.bold:        true
					wrapMode:         Text.WordWrap
					maximumLineCount: 2
					elide:            Text.ElideRight
					visible:          text !== ""
				}

				Text {
					width:            parent.width
					text:             root.current?.body ?? ""
					color:            Theme.subtext
					font.pixelSize:   Math.round(12 * root.localScale) | 0
					wrapMode:         Text.WordWrap
					maximumLineCount: 2
					elide:            Text.ElideRight
					textFormat:       Text.StyledText
					visible:          text !== ""
				}

				Row {
					spacing:    Math.round(6 * root.localScale)
					topPadding: Math.round(2 * root.localScale)
					visible:    (root.current?.actions?.length ?? 0) > 0

					Repeater {
						model: root.current?.actions ?? []
						delegate: Item {
							required property var modelData
							width:  actionLbl.width + Math.round(20 * root.localScale)
							height: Math.round(24 * root.localScale)
							Rectangle {
								anchors.fill: parent
								radius:       Math.round(4 * root.localScale)
								color:        actHover.containsMouse
								? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.18)
								: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.08)
								Behavior on color { ColorAnimation { duration: Anim.fast} }
							}
							Text {
								id:               actionLbl
								anchors.centerIn: parent
								text:             modelData?.text ?? ""
								color:            Theme.text
								font.pixelSize:   Math.round(11 * root.localScale) | 0
							}
							HoverHandler { id: actHover }
							TapHandler {
								onTapped: {
									modelData?.invoke()
									root.startDismiss()
								}
							}
						}
					}
				}
			}

			HoverHandler {
				id: toastHover
				onHoveredChanged: {
					if (hovered) {
						autoTimer.pause()
					} else {
						if (root.showing) {
							autoTimer.resume()
						}
					}
				}
			}
		}
	}
}
