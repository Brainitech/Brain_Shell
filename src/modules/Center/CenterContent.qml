import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Io
import "../../"
import "../../services/home/."

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
	readonly property int fw: Math.round(Theme.notchRadius * localScale)
	readonly property int requiredWidth: Math.round(Theme.cNotchMinWidth * localScale)
	// ── MPRIS ─────────────────────────────────────────────────────────────────
	readonly property var    player:    Mpris.players.values.length > 0
	? Mpris.players.values[0] : null
	readonly property bool   isPlaying: player?.playbackState === MprisPlaybackState.Playing
	?? false
	readonly property string artUrl:    player?.trackArtUrl ?? ""

	property string activeTitle: "Desktop"

	// ── App name helper ───────────────────────────────────────────────────────    
	// 2. Process to fetch the initialTitle
	property var _titleProc: Process {
		command: ["hyprctl", "activewindow", "-j"]
		running: false

		onRunningChanged: {
			if (running) {
			}
		}

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
				NumberAnimation { duration: Anim.mediumSlow; easing.type: Anim.outCubic}
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
					// leftPadding:  8u					rightPadding: 8
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
												Behavior on height {
													NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic}
												}
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

							// Icon — left edge of notch
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

							// Time display — centered in remaining space
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

								// Blink when urgent — opacity pulses 1 → 0.25 → 1
								SequentialAnimation on opacity {
									id: timerBlink
									running:  root.timerUrgent
									loops:    Animation.Infinite
									NumberAnimation { to: 0.25; duration: Anim.verySlow; easing.type: Anim.inOutSine}
									NumberAnimation { to: 1.0;  duration: Anim.verySlow; easing.type: Anim.inOutSine}
								}

								// Snap back to full opacity when blink stops
								Connections {
									target: timerBlink
									function onRunningChanged() {
										if (!timerBlink.running) timerText.opacity = 1.0
									}
								}
							}
							// Icon — right edge of notch
							Row{
								anchors {
									right:          parent.right
									rightMargin:    root.fw
									verticalCenter: parent.verticalCenter
								}
								spacing: root.fw

								Text {
									anchors {
										verticalCenter: parent.verticalCenter
									}
									text:           ClockState.timerRunning ? "󱫟" : "󱫡"
									font.pixelSize: Math.round(16 * localScale)
									color:          _timerPauseHov.hovered ? Theme.active : Theme.text
									HoverHandler { id: _timerPauseHov;  }
									MouseArea {
										anchors.fill: parent
										cursorShape: Qt.PointingHandCursor
										onClicked: ClockState.timerRunning = !ClockState.timerRunning
									}
								}
								Text {
									anchors {
										verticalCenter: parent.verticalCenter
									}
									text:			"󱫥"
									font.pixelSize: Math.round(16 * localScale)
									color:			_timerResetHov.hovered ? Theme.active : Theme.text
									HoverHandler { id: _timerResetHov; cursorShape: Qt.PointingHandCursor }
									MouseArea {
										anchors.fill: parent
										cursorShape: Qt.PointingHandCursor
										onClicked: {
											ClockState.requestTimerReset()
										}
									}
								}
							}
						}
						// ── Stopwatch ──────────────────────────────────────────────────
						Item {
							anchors.fill: parent
							visible:      modelData === "stopwatch"

							// Icon — left edge of notch
							Text {
								anchors {
									left:           parent.left
									leftMargin:     root.fw
									verticalCenter: parent.verticalCenter
								}
								text:           ""
								font.pixelSize: Math.round(16 * localScale)
								color:          Theme.active
							}

							// Running time — centered in remaining space
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
							// Icon — right edge of notch
							Row{
								anchors {
									right:          parent.right
									rightMargin:    root.fw
									verticalCenter: parent.verticalCenter
								}
								spacing: root.fw
								
								Text {
									anchors {
										verticalCenter: parent.verticalCenter
									}
									text:           ClockState.swRunning ? "󱫟" : "󱫡"
									font.pixelSize: Math.round(16 * localScale)
									color:          _pauseHov.hovered ? Theme.active : Theme.text
									HoverHandler { id: _pauseHov;  }
									MouseArea {
										anchors.fill: parent
										cursorShape: Qt.PointingHandCursor
										onClicked: {
										ClockState.swRunning = !ClockState.swRunning
										}
									}
								}
								Text {
									anchors {
										verticalCenter: parent.verticalCenter
									}
									text:			"󱫥"
									font.pixelSize: Math.round(16 * localScale)
									color:			_notchResetHov.hovered ? Theme.active : Theme.text
										
									HoverHandler { id: _notchResetHov; cursorShape: Qt.PointingHandCursor }
									MouseArea {
											anchors.fill: parent
											cursorShape: Qt.PointingHandCursor
											onClicked: {
												ClockState.requestStopwatchReset()
											}
										}
									}
							}
						}

						// ── Record setup — strip buttons + Record button ───────────────
						Item {
							anchors{
								fill: parent
								leftMargin: root.fw/2
								rightMargin: root.fw/2
							}
							
							visible:      modelData === "record_setup"

							Row {
								anchors { fill: parent; leftMargin: Math.round(8 * localScale); rightMargin: Math.round(8 * localScale) }
								spacing: Math.round(6 * localScale)

								// ── Capture strip button ───────────────────────────────
								Item {
									anchors.verticalCenter: parent.verticalCenter
									width:  csRow.implicitWidth + Math.round(14 * localScale)
									height: Math.round(22 * localScale)

									Rectangle {
										anchors.fill: parent
										radius:       height / 2
										color: ScreenRecService.openStrip === "capture"
										? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15)
										: csH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.08) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.04)
										border.color: ScreenRecService.openStrip === "capture"
										? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.3)
										: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.1)
										border.width: 1
										Behavior on color        { ColorAnimation { duration: Anim.fast} }
										Behavior on border.color { ColorAnimation { duration: Anim.fast} }
									}
									Row {
										id: csRow
										anchors.centerIn: parent
										spacing: Math.round(5 * localScale)
										Text {
											text: ScreenRecService.captureIcon
											font.pixelSize: Math.round(13 * localScale)
											color: ScreenRecService.openStrip === "capture"
											? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.7)
											anchors.verticalCenter: parent.verticalCenter
											Behavior on color { ColorAnimation { duration: Anim.fast} }
										}
										Text {
											text: ScreenRecService.captureLabel
											font.pixelSize: Math.round(11 * localScale)
											color: ScreenRecService.openStrip === "capture"
											? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.7)
											anchors.verticalCenter: parent.verticalCenter
											Behavior on color { ColorAnimation { duration: Anim.fast} }
										}
										Text {
											text: "▾"; font.pixelSize: Math.round(8 * localScale)
											color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.35)
											anchors.verticalCenter: parent.verticalCenter
										}
									}
									HoverHandler {
										id: csH
										onHoveredChanged: {
											if (hovered) {
												var pos = parent.mapToItem(null, 0, 0)
												ScreenRecService.popupTargetX = pos.x
												ScreenRecService.popupTargetWidth = parent.width

												ScreenRecService.openStrip = "capture"
												ScreenRecService.keepStripOpen()
											} else {
												ScreenRecService.scheduleStripClose()
											}
										}
									}
								}

								// ── Audio strip button ─────────────────────────────────
								Item {
									anchors.verticalCenter: parent.verticalCenter
									width:  asRow.implicitWidth + Math.round(14 * localScale)
									height: Math.round(22 * localScale)

									Rectangle {
										anchors.fill: parent
										radius:       height / 2
										color: ScreenRecService.openStrip === "audio"
										? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15)
										: asH.hovered ? Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.08) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.04)
										border.color: ScreenRecService.openStrip === "audio"
										? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.3)
										: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.1)
										border.width: 1
										Behavior on color        { ColorAnimation { duration: Anim.fast} }
										Behavior on border.color { ColorAnimation { duration: Anim.fast} }
									}
									Row {
										id: asRow
										anchors.centerIn: parent
										spacing: Math.round(5 * localScale)
										Text {
											text: "🎙"; font.pixelSize: Math.round(12 * localScale)
											anchors.verticalCenter: parent.verticalCenter
										}
										Text {
											text: ScreenRecService.audioLabel
											font.pixelSize: Math.round(11 * localScale)
											color: ScreenRecService.openStrip === "audio"
											? Theme.active : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.7)
											anchors.verticalCenter: parent.verticalCenter
											Behavior on color { ColorAnimation { duration: Anim.fast} }
										}
										Text {
											text: "▾"; font.pixelSize: Math.round(8 * localScale)
											color: Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.35)
											anchors.verticalCenter: parent.verticalCenter
										}
									}
									HoverHandler {
										id: asH
										onHoveredChanged: {
											if (hovered) {
												var pos = parent.mapToItem(null, 0, 0)
												ScreenRecService.popupTargetX = pos.x
												ScreenRecService.popupTargetWidth = parent.width

												ScreenRecService.openStrip = "audio"
												ScreenRecService.keepStripOpen()
											} else {
												ScreenRecService.scheduleStripClose()
											}
										}
									}
								}

								// Flexible spacer
								Item {
									anchors.verticalCenter: parent.verticalCenter
									height: 1
									width: parent.width
									- csRow.implicitWidth - Math.round(14 * localScale)
									- asRow.implicitWidth - Math.round(14 * localScale)
									- recBtnLabel.implicitWidth - Math.round(24 * localScale)
									- parent.spacing * 3
								}

								// ── Record button ──────────────────────────────────────
								Rectangle {
									anchors.verticalCenter: parent.verticalCenter
									width:  recBtnLabel.implicitWidth + Math.round(24 * localScale)
									height: Math.round(22 * localScale)
									radius: height / 2
									color:  recBtnH.hovered
									? Qt.rgba(0.9, 0.2, 0.2, 0.85)
									: Qt.rgba(0.8, 0.1, 0.1, 0.7)
									Behavior on color { ColorAnimation { duration: Anim.fast} }
									Row {
										anchors.centerIn: parent
										spacing: Math.round(5 * localScale)
										Rectangle {
											width: Math.round(7 * localScale); height: Math.round(7 * localScale); radius: Math.round(4 * localScale)
											color: "#ffffff"
											anchors.verticalCenter: parent.verticalCenter
										}
										Text {
											id: recBtnLabel
											text: "Record"
											font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium
											color: "#ffffff"
											anchors.verticalCenter: parent.verticalCenter
										}
									}
									HoverHandler { id: recBtnH}
									MouseArea { anchors.fill: parent;cursorShape: Qt.PointingHandCursor; onClicked: ScreenRecService.startRecording() }
								}
							}
						}

						// ── Record active — ● (Left) | Timer + Cava (Center) | Trash + Stop (Right) ──
						Item {
							anchors{
								fill: parent
								leftMargin: root.fw/2
								rightMargin: root.fw/2
							}
							visible:      modelData === "record_active"

							// Left: dot + timer, anchored left
							Row {
								anchors {
									left:           parent.left
									leftMargin:     Math.round(10 * localScale)
									verticalCenter: parent.verticalCenter
								}
								spacing: Math.round(7 * localScale)

								// Pulsing red dot
								Rectangle {
									width:  Math.round(8 * localScale); height: Math.round(8 * localScale); radius: Math.round(4 * localScale)
									color:  "#ff4444"
									anchors.verticalCenter: parent.verticalCenter
									SequentialAnimation on opacity {
										running: ScreenRecService.recording
										loops:   Animation.Infinite
										NumberAnimation { to: 0.25; duration: Anim.extraSlow; easing.type: Anim.inOutSine}
										NumberAnimation { to: 1.0;  duration: Anim.extraSlow; easing.type: Anim.inOutSine}
									}
								}

								// Elapsed time
								Text {
									anchors.verticalCenter: parent.verticalCenter
									text:           ScreenRecService.elapsedDisplay
									font.pixelSize: Math.round(13 * localScale); font.weight: Font.Bold
									font.family:    "JetBrains Mono"
									color:          Theme.text
								}
							}

							// Center: cava
							Item {
								id: recCava
								anchors.centerIn: parent
								width:  Math.round(44 * localScale)
								height: Math.round(20 * localScale)

								readonly property real _bw:   Math.round(4 * localScale)
								readonly property real _sp:   Math.max(1, (width - _bw * 12) / 5)
								readonly property real _maxH: height / 2

								Row {
									anchors.fill: parent
									spacing:      recCava._sp

									Repeater {
										model: ScreenRecService.audioBars
										delegate: Item {
											required property int modelData
											width:  recCava._bw
											height: recCava.height
											readonly property real _amp: modelData / 100.0
											Rectangle {
												anchors.centerIn: parent
												width:  recCava._bw
												height: Math.max(2, _amp * recCava._maxH * 2)
												radius: width / 2
												color: ScreenRecService.audioMic || ScreenRecService.audioSystem
												? Qt.rgba(0.95, 0.3, 0.3, 0.30 + _amp * 0.70)
												: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
												Behavior on height {
													NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic}
												}
											}
										}
									}
								}
							}

							// Right: trash + stop, anchored right
							Row {
								anchors {
									right:          parent.right
									rightMargin:    Math.round(10 * localScale)
									verticalCenter: parent.verticalCenter
								}
								spacing: root.fw/2

								// Discard button
								Rectangle {
									anchors.verticalCenter: parent.verticalCenter
									width: Math.round(22 * localScale); height: Math.round(22 * localScale); radius: Math.round(5 * localScale)
									color: recDiscardH.hovered
									? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
									: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
									Behavior on color { ColorAnimation { duration: Anim.fast} }
									Text {
										anchors.centerIn: parent
										text:           "󰩺"
										font.pixelSize: Math.round(11 * localScale)
										color:          recDiscardH.hovered
										? Qt.rgba(1, 0.4, 0.4, 1.0)
										: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
										Behavior on color { ColorAnimation { duration: Anim.fast} }
									}
									HoverHandler { id: recDiscardH }
									MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ScreenRecService.discardRecording() }
								}

								// Stop button
								Rectangle {
									anchors.verticalCenter: parent.verticalCenter
									width: Math.round(22 * localScale); height: Math.round(22 * localScale); radius: Math.round(5 * localScale)
									color: recStopH.hovered
									? Qt.rgba(0.9, 0.2, 0.2, 0.55)
									: Qt.rgba(0.8, 0.1, 0.1, 0.32)
									Behavior on color { ColorAnimation { duration: Anim.fast} }
									Text {
										anchors.centerIn: parent
										text:           "⏹"
										font.pixelSize: Math.round(10 * localScale)
										color:          "#ff9999"
									}
									HoverHandler { id: recStopH }
									MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ScreenRecService.stopRecording() }
								}
							}
						}

					} // delegate
				}
			}

			// ── Click to toggle dashboard ─────────────────────────────────────────────
			// TapHandler has lower implicit grab priority than child MouseAreas.
			// Clicks on Stop / Discard buttons are handled by their own MouseAreas
			// first and never reach here. Tapping empty notch space opens dashboard.
			TapHandler {
				onTapped: {
					// Do nothing during screen rec setup — ESC / cancel button handles it
					if (ShellState.screenRecord && !ScreenRecService.recording) return
					var next = !Popups.dashboardOpen
					Popups.closeAll()
					Popups.dashboardOpen = next
					if (next) Popups.dashboardPinned = true
				}
			}

			HoverHandler {
				onHoveredChanged: Popups.dashboardTriggerHovered = hovered
			}
		}
