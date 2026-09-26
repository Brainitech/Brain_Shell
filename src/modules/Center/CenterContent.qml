import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import Quickshell.Io
import "../../"

// CenterContent — scrollable dynamic island carousel.
//
// Active item order:
//   "title"     — always present (default)
//   "music"     — MPRIS player present
//   "timer"     — ClockState.timerRunning
//   "stopwatch" — ClockState.swRunning
//
// CenterNotchMonitor (internal QtObject) watches ClockState and
// handles urgent transitions:
//   • timer <= 30s remaining → force-scroll to timer, text blinks red
//   • stopwatch active → appears in carousel, scrolls if on title
//
// Cava bars: single Rectangle per bar, anchors.centerIn — grows
// symmetrically. No center rounding artefact. 5px wide.

Item {
	id: root

	property real localScale: 1.0
	width:  Math.round(Theme.cNotchMinWidth * localScale)
	height: Math.round(30 * localScale)

	// ── Required notch width for the current carousel item ────────────────────
	// TopBar.cWidth reads this so the notch always matches what is visible,
	// even if the user scrolls away from record_active while recording.
	readonly property int fw: Math.round(Theme.cornerRadius * localScale)
	// ── MPRIS (via MediaService) ─────────────────────────────────────────────
	readonly property var    player:    MediaService.activePlayer
	readonly property bool   isPlaying: MediaService.isPlaying
	readonly property string artUrl:    MediaService.artUrl

	property string activeTitle: "Desktop"

	// ── App name helper ───────────────────────────────────────────────────────    
	// 2. Process to fetch the initialTitle
	property var _titleProc: Process {
		command: ["hyprctl", "activewindow", "-j"]
		running: false

		stdout: StdioCollector {
			id: titleOut
		}

		onExited: function(exitCode, exitStatus) {

			var out = titleOut.text.trim()            
			// Check for empty, Invalid, or empty JSON object
			if (exitCode !== 0 || out === "" || out === "Invalid" || out === "{}") {
				root.activeTitle = "Desktop"
				return
			}

			try {
				// Parse the JSON natively in Quickshell
				var data = JSON.parse(out)
				var title = data.initialTitle || ""

				if (title !== "") {
					// Capitalize the first letter (e.g., "kitty" -> "Kitty")
					var finalTitle = title.charAt(0).toUpperCase() + title.slice(1)
					root.activeTitle = finalTitle
				} else {
					root.activeTitle = "Desktop"
				}
			} catch(e) {
				root.activeTitle = "Desktop"
			}
		}
	}

	Connections{
		target: Hyprland
		// 3. Your Raw Event Monitor
		function onRawEvent(event) {
			// 3. Trigger title fetch on any window/workspace focus change
			var titleTriggers = ["workspace", "activewindow", "activespecial", "destroyworkspace", "closewindow", "changefloatingmode"]

			if (titleTriggers.includes(event.name)) {
				_titleProc.running = false
				_titleProc.running = true
			}
		}
	}

	// ── Dynamic item list ─────────────────────────────────────────────────────
	property var  _items:         ["title"]
	property int  _carouselIndex: 0
    on_CarouselIndexChanged: {
        CavaService.notchMusicVisible = (_items.indexOf("music") >= 0 && _carouselIndex === _items.indexOf("music"))
    }
	readonly property real _itemStride: Math.round(45 * localScale)  // 30px height + 15px spacing

	function _rebuildItems(autoScrollType) {
		var currentType = (_items.length > _carouselIndex)
		? _items[_carouselIndex] : "title"

		var list = ["title"]
		if (root.player !== null || CavaService.audioActive) list.push("music")
		if (ClockState.timerStarted)                   list.push("timer")
		if (ClockState.swStarted)                      list.push("stopwatch")
		if (ShellState.screenRecord && !ScreenRecService.recording) list.push("record_setup")
		if (ScreenRecService.recording)           list.push("record_active")

		root._items = list

		var idx = list.indexOf(currentType)
		if (idx < 0) idx = 0

		if (autoScrollType) {
			var nIdx = list.indexOf(autoScrollType)
			if (nIdx >= 0) {
				// Screen rec always takes priority — scroll regardless of where we are.
				// Other items only auto-scroll when coming from "title".
				var isScreenRec = (autoScrollType === "record_setup" ||
				autoScrollType === "record_active")
				if (isScreenRec || currentType === "title")
				idx = nIdx
			}
		}

		root._carouselIndex = idx
		statusList.contentY = idx * root._itemStride

		// Signal CavaService whether music carousel is visible
		CavaService.notchMusicVisible = (list.indexOf("music") >= 0 && root._carouselIndex === list.indexOf("music"))
	}

	// Force-scroll to a specific type regardless of where the user is
	function _forceScrollTo(type) {
		var idx = root._items.indexOf(type)
		if (idx < 0) return
		root._carouselIndex = idx
		statusList.contentY = idx * root._itemStride
	}

	onPlayerChanged: _rebuildItems(player !== null ? "music" : null)

	Connections {
		target: CavaService
		function onAudioActiveChanged() {
			_rebuildItems(CavaService.audioActive ? "music" : null)
		}
	}

	// ── State monitor — timer urgency + carousel transitions ─────────────────
	readonly property bool timerUrgent:
	ClockState.timerRunning && ClockState.timerLeft <= 30 && ClockState.timerLeft > 0

	Connections {
		target: ClockState

		function onTimerRunningChanged() {
			root._rebuildItems(ClockState.timerRunning ? "timer" : null)
		}

		function onSwStartedChanged() {
			root._rebuildItems(ClockState.swStarted ? "stopwatch" : null)
			root._forceScrollTo("stopwatch")
		}

		function onTimerLeftChanged() {
			if (ClockState.timerRunning && ClockState.timerLeft === 30 || ClockState.timerRunning && ClockState.timerLeft === 10)
			root._forceScrollTo("timer")
		}
		
		function onTimerStartedChanged() {
			root._rebuildItems(ClockState.timerStarted ? "timer" : null)
			root._forceScrollTo("timer")
		}
	}

	Connections {
		target: ShellState
		function onScreenRecordChanged() {
			if (ShellState.screenRecord && !ScreenRecService.recording)
			root._rebuildItems("record_setup")
			else if (!ShellState.screenRecord)
			root._rebuildItems(null)
		}
	}

	Connections {
		target: ScreenRecService
		function onRecordingChanged() {
			if (ScreenRecService.recording)
			root._rebuildItems("record_active")
			else
			root._rebuildItems(null)
		}
	}

	// ── Scroll debounce ───────────────────────────────────────────────────────
	property bool _scrollBusy: false
	Timer {
		id: scrollCooldown
		interval: 250
		onTriggered: root._scrollBusy = false
	}

	// ── Cava — shared via CavaService singleton ─────────────────────────────
	readonly property int _cavaBars: CavaService.barCount
	readonly property var _bars:     CavaService.bars

	// ── Carousel ──────────────────────────────────────────────────────────────
	Item {
		anchors.fill: parent

		opacity: Popups.dashboardOpen ? 0 : 1
		visible: opacity > 0
		Behavior on opacity { NumberAnimation { duration: Anim.mediumFast} }

		// ── Click to toggle dashboard (Bottom of Z-order to not block buttons) ─────
		MouseArea {
			anchors.top: parent.top
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.topMargin: Math.round(-1 * localScale)
			width: parent.width
			height: Math.round((Theme.notchHeight + 3) * localScale)
			
			onClicked: {
				if (ShellState.screenRecord && !ScreenRecService.recording) {
					var pos = root.mapToItem(null, 0, 0)
					ScreenRecService.popupTargetX = pos.x
					ScreenRecService.popupTargetWidth = root.width
					ScreenRecService.optionsExpanded = !ScreenRecService.optionsExpanded
					return
				}
				if (Popups.dashboardOpen && Popups.dashboardAllowHover) {
					Popups.dashboardPinned = !Popups.dashboardPinned
					return
				}
				var next = !Popups.dashboardOpen
				Popups.closeAll()
				SurfaceState.toggle("top", "dashboard")
				if (next) Popups.dashboardPinned = true
			}
		}

		WheelHandler {
			acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
			onWheel: function(event) {
				// Block scroll only during setup (not during active recording)
				if (ShellState.screenRecord && !ScreenRecService.recording) return
				if (root._scrollBusy) return
				root._scrollBusy = true
				scrollCooldown.restart()

				var maxIdx = root._items.length - 1
				if (event.angleDelta.y < 0)
				root._carouselIndex = Math.min(maxIdx, root._carouselIndex + 1)
				else
				root._carouselIndex = Math.max(0, root._carouselIndex - 1)

				statusList.contentY = root._carouselIndex * root._itemStride
			}
		}

		ListView {
			id: statusList
			anchors.fill: parent
			orientation:  ListView.Vertical
			spacing:      Math.round(15 * localScale)
			clip:         true
			snapMode:     ListView.SnapOneItem
			interactive:  false

			Behavior on contentY {
				NumberAnimation { duration: Anim.mediumSlow; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod}
			}

			model: root._items

			delegate: Item {
				required property string modelData
				required property int    index

				width:  Math.round(Theme.cNotchMinWidth * localScale)
				height: statusList.height

				// ── Title ──────────────────────────────────────────────────────
				Text {
					anchors.fill: parent
					visible:      modelData === "title"
					text:         root.activeTitle
					color:        Theme.text
					font.pixelSize: Math.round(13 * localScale)
					verticalAlignment:   Text.AlignVCenter
					horizontalAlignment: Text.AlignHCenter
					elide:        Text.ElideRight
				}

				// ── Music ──────────────────────────────────────────────────────
				Item {
					anchors.fill: parent
					anchors.leftMargin: root.fw/2
					anchors.rightMargin: root.fw/2
					visible:      modelData === "music"

					readonly property int artSize: Math.round(20 * localScale)
					readonly property int artPad:  Math.round(7 * localScale)

					Item {
						x:    parent.artPad
						anchors.verticalCenter: parent.verticalCenter
						width:  parent.artSize
						height: parent.artSize

						Rectangle {
							anchors.fill:  parent
							radius:        width / 2
							color:         Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
							border.color:  Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.38)
							border.width:  1
							visible:       root.artUrl === ""
							Text {
								anchors.centerIn: parent
								text:           "♪"
								font.pixelSize: Math.round(9 * localScale)
								color:          Theme.active
							}
						}

						Rectangle {
							id:            artMask
							anchors.fill:  parent
							radius:        width / 2
							visible:       false
							layer.enabled: true
						}

						Image {
							anchors.fill:  parent
							source:        root.artUrl
							fillMode:      Image.PreserveAspectCrop
							smooth:        true
							cache:         true
							visible:       root.artUrl !== ""
							layer.enabled: true
							layer.effect: MultiEffect {
								maskEnabled:      true
								maskSource:       artMask
								maskThresholdMin: 0.5
								maskSpreadAtMin:  1.0
							}
						}

						HoverHandler { id: _miniPlayerHov; cursorShape: Qt.PointingHandCursor }
						MouseArea {
							anchors.fill: parent
							onClicked: Popups.miniPlayerOpen = !Popups.miniPlayerOpen
						}
					}

					Item {
						id: barsArea
						anchors {
							left:        parent.left
							leftMargin:  parent.artPad + parent.artSize + Math.round(5 * localScale)
							right:       parent.right
							rightMargin: Math.round(5 * localScale)
							top:         parent.top
							bottom:      parent.bottom
						}

						readonly property real _barW:       Math.round(5 * localScale)
						readonly property real _barSpacing: Math.max(
							1,
							(width - _barW * root._cavaBars) / Math.max(1, root._cavaBars - 1))
						readonly property real _maxBarH:    height / 2

						Row {
							anchors.fill: parent
							spacing:      barsArea._barSpacing

							Repeater {
								model: root._bars
								delegate: Item {
									required property int modelData
									width:  barsArea._barW
									height: barsArea.height
									readonly property real _amp: modelData / 100.0
									Rectangle {
										anchors.centerIn: parent
										width:  barsArea._barW
										height: Math.max(2, _amp * barsArea._maxBarH * 2)
										radius: width / 2
										color:  Qt.rgba(
											Theme.active.r, Theme.active.g, Theme.active.b,
											0.28 + _amp * 0.72)
									}
								}
							}
						}
					}
				}

				// ── Timer ──────────────────────────────────────────────────────
				Item {
					anchors.fill: parent
					visible:      modelData === "timer"

					Text {
						anchors {
							left:           parent.left
							leftMargin:     root.fw
							verticalCenter: parent.verticalCenter
						}
						text:           "󰔟"
						font.pixelSize: Math.round(16 * localScale)
						color:          root.timerUrgent ? "#ff5555" : Theme.active
						Behavior on color { ColorAnimation { duration: Anim.normal} }
					}

					Text {
						id: timerText
						anchors {
							left:           parent.left
							leftMargin:     Math.round(8 * localScale)
							right:          parent.right
							rightMargin:    Math.round(8 * localScale)
							verticalCenter: parent.verticalCenter
						}
						text:           ClockState.timerDisplay
						font.pixelSize: Math.round(15 * localScale)
						font.weight:    Font.Bold
						font.family:    "JetBrains Mono"
						horizontalAlignment: Text.AlignHCenter
						color:          root.timerUrgent ? "#ff5555" : Theme.text
						Behavior on color { ColorAnimation { duration: Anim.normal} }

						SequentialAnimation on opacity {
							id: timerBlink
							running:  root.timerUrgent
							loops:    Animation.Infinite
							NumberAnimation { to: 0.25; duration: Anim.verySlow; easing.type: Anim.inOutSine}
							NumberAnimation { to: 1.0;  duration: Anim.verySlow; easing.type: Anim.inOutSine}
						}

						Connections {
							target: timerBlink
							function onRunningChanged() {
								if (!timerBlink.running) timerText.opacity = 1.0
							}
						}
					}

					Row{
						anchors {
							right:          parent.right
							rightMargin:    root.fw
							verticalCenter: parent.verticalCenter
						}
						spacing: root.fw

						Text {
							anchors.verticalCenter: parent.verticalCenter
							text:           ClockState.timerRunning ? "󱫟" : "󱫡"
							font.pixelSize: Math.round(16 * localScale)
							color:          _timerPauseHov.hovered ? Theme.active : Theme.text
							HoverHandler { id: _timerPauseHov }
							MouseArea { 
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								onClicked: ClockState.timerRunning = !ClockState.timerRunning
							}
						}
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text:           "󱫥"
							font.pixelSize: Math.round(16 * localScale)
							color:          _timerResetHov.hovered ? Theme.active : Theme.text
							HoverHandler { id: _timerResetHov; cursorShape: Qt.PointingHandCursor }
							MouseArea { 
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								onClicked: ClockState.requestTimerReset()
							}
						}
					}
				}

				// ── Stopwatch ──────────────────────────────────────────────────
				Item {
					anchors.fill: parent
					visible:      modelData === "stopwatch"

					Text {
						anchors {
							left:           parent.left
							leftMargin:     root.fw
							verticalCenter: parent.verticalCenter
						}
						text:           ""
						font.pixelSize: Math.round(16 * localScale)
						color:          Theme.active
					}

					Text {
						anchors {
							left:           parent.left
							leftMargin:     Math.round(8 * localScale)
							right:          parent.right
							rightMargin:    Math.round(8 * localScale)
							verticalCenter: parent.verticalCenter
						}
						text:           ClockState.swDisplay
						font.pixelSize: Math.round(15 * localScale)
						font.weight:    Font.Bold
						font.family:    "JetBrains Mono"
						horizontalAlignment: Text.AlignHCenter
						color:          Theme.text
					}

					Row{
						anchors {
							right:          parent.right
							rightMargin:    root.fw
							verticalCenter: parent.verticalCenter
						}
						spacing: root.fw
						
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text:           ClockState.swRunning ? "󱫟" : "󱫡"
							font.pixelSize: Math.round(16 * localScale)
							color:          _pauseHov.hovered ? Theme.active : Theme.text
							HoverHandler { id: _pauseHov }
							MouseArea { 
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								onClicked: ClockState.swRunning = !ClockState.swRunning
							}
						}
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text:           "󱫥"
							font.pixelSize: Math.round(16 * localScale)
							color:          _notchResetHov.hovered ? Theme.active : Theme.text
							HoverHandler { id: _notchResetHov; cursorShape: Qt.PointingHandCursor }
							MouseArea { 
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								onClicked: ClockState.requestStopwatchReset()
							}
						}
					}
				}

				ScreenRecordSetupDelegate { anchors.fill: parent; localScale: root.localScale; fw: root.fw; itemType: modelData }
				ScreenRecordActiveDelegate { anchors.fill: parent; localScale: root.localScale; fw: root.fw; itemType: modelData }

			} // delegate
		}



		HoverHandler {
			onHoveredChanged: {
				Popups.dashboardTriggerHovered = hovered
				if (ShellState.screenRecord && !ScreenRecService.recording && PrefsService.globalHoverMode && PrefsService.hoverDashboard) {
					if (hovered) ScreenRecService.requestExpand()
					else ScreenRecService.scheduleClose()
				}
			}
		}
	}
}
