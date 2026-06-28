import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../shapes/"
import "../services/"
import "../"

PopupWindow {
	id: root

	required property var anchorWindow
    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    readonly property int fw: Math.round(Theme.notchRadius * localScale)
    readonly property int fh: Math.round(Theme.notchRadius * localScale)

    readonly property int toastWidth: Math.round(Theme.notificationToastWidth * localScale) + Math.round(10 * localScale)

    implicitWidth:  toastWidth + fw + Math.round(10 * localScale)
    implicitHeight: Math.round(180 * localScale)

    anchor.window: root.anchorWindow
    anchor.rect: Qt.rect(
        Math.round(root.anchorWindow.width - ((toastWidth + (fw*2)+ Theme.borderWidth)/2)),
        Math.round((-Theme.notchHeight / 2) * localScale),
        0,
        0
    )
    anchor.gravity:    Edges.Bottom
    anchor.adjustment: PopupAdjustment.None

	color:   "transparent"
	visible: windowVisible

	Region {
		id: toastBlurReg
		item: card
	}

	BackgroundEffect.blurRegion: PrefsService.bgBlur ? toastBlurReg : null

	property bool windowVisible: false
	property bool showing:       false
	property var  current:       null
	property var  queue:         []

	Connections {
		target: NotificationService
		function onNotificationAdded(n) {
			if (!n || !n.tracked) return
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
		root.windowVisible = true
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

	Timer {
		id:          autoTimer
		interval:    5000
		onTriggered: root.startDismiss()
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
				root.windowVisible = false
			}
		}
	}

	// ── Card ───────────────────────────────────────────────────
	Item {
		id:            card
		anchors.right: parent.right
		anchors.top:   parent.top
		clip:           true


		width: root.showing
		? root.toastWidth + root.fw
		: root.fw

		height: root.showing
		? (cardCol.y + cardCol.implicitHeight + Math.round(24 * root.localScale) + root.fh)
		: root.fh

		Behavior on width  { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }
		Behavior on height { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }

		PopupShape {
			anchors.fill: parent
			attachedEdge: "right"
			color:        Theme.background
			radius:       Math.round(Theme.cornerRadius * root.localScale)
			flareWidth:   root.fw
			flareHeight:  root.fh
		}

		Rectangle {
			anchors {
				right:        parent.right
				top:          parent.top
				bottom:       parent.bottom
				topMargin:    fh*1.2
				bottomMargin: fh*1.2
				rightMargin:  root.fw
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
					rightMargin: root.fw
					bottom:      cardCol.bottom
					bottomMargin: Math.round(-10 * root.localScale)
				}
				height:  Math.round(2 * root.localScale)
				radius:  Math.round(1 * root.localScale)
				color:   Theme.active
				opacity: 0.5

				property bool running: false

				// Use toastWidth so the bar stays within the visible body, not the flare
				width: running ? 0 : root.toastWidth - Math.round(10 * root.localScale)
				Behavior on width {
					enabled: progressBar.running
					NumberAnimation { duration: Anim.megaSlow; easing.type: Anim.linear}
				}

				Connections {
					target: root
					function onShowingChanged() {
						if (root.showing) {
							progressBar.running = false
							progressTick.restart()
						} else {
							progressBar.running = false
						}
					}
				}

				Timer {
					id:          progressTick
					interval:    16
					onTriggered: progressBar.running = true
				}
			}

			Column {
				id: cardCol
				anchors {
					left:       parent.left;  leftMargin:  Math.round(14 * root.localScale)
					right:      parent.right; rightMargin: root.fw + Math.round(6 * root.localScale)

				}
				spacing: Math.round(2 * root.localScale)
				bottomPadding: Math.round(10 * root.localScale)
				y: root.fh + Math.round(6 * root.localScale)
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

					Item {
						width:  Math.round(20 * root.localScale)
						height: Math.round(20 * root.localScale)
						anchors.verticalCenter: parent.verticalCenter
						Rectangle {
							anchors.fill: parent
							radius:       width / 2
							color:        xHover.containsMouse ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.12) : "transparent"
							Behavior on color { ColorAnimation { duration: Anim.fast} }
						}
						Text {
							anchors.centerIn: parent
							text:             "✕"
							color:            Theme.subtext
							font.pixelSize:   Math.round(9 * root.localScale) | 0
						}
						HoverHandler { id: xHover }
						TapHandler   { onTapped: root.startDismiss() }
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
		}
	}
}
