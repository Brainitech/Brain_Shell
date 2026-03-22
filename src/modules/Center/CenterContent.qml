import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import Quickshell.Services.Mpris
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

    width:  Theme.cNotchMinWidth
    height: 30

    // ── MPRIS ─────────────────────────────────────────────────────────────────
    readonly property var    player:    Mpris.players.values.length > 0
                                        ? Mpris.players.values[0] : null
    readonly property bool   isPlaying: player?.playbackState === MprisPlaybackState.Playing
                                        ?? false
    readonly property string artUrl:    player?.trackArtUrl ?? ""

    // ── App name helper ───────────────────────────────────────────────────────
    function _appName() {
        var tl = Hyprland.activeToplevel
        if (!tl) return "Desktop"
        var id = tl.appId || ""
        if (id === "") return tl.title || "Desktop"
        return id.split(/[-_.]/)
                 .map(function(w) {
                     return w.length > 0
                         ? w.charAt(0).toUpperCase() + w.slice(1) : ""
                 })
                 .join(" ").trim()
    }

    // ── Dynamic item list ─────────────────────────────────────────────────────
    property var  _items:         ["title"]
    property int  _carouselIndex: 0
    readonly property real _itemStride: 45  // 30px height + 15px spacing

    function _rebuildItems(autoScrollType) {
        var currentType = (_items.length > _carouselIndex)
                          ? _items[_carouselIndex] : "title"

        var list = ["title"]
        if (root.player        !== null) list.push("music")
        if (ClockState.timerRunning)     list.push("timer")
        if (ClockState.swRunning)        list.push("stopwatch")

        root._items = list

        var idx = list.indexOf(currentType)
        if (idx < 0) idx = 0

        if (autoScrollType && currentType === "title") {
            var nIdx = list.indexOf(autoScrollType)
            if (nIdx >= 0) idx = nIdx
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

    // ── State monitor — timer urgency + carousel transitions ─────────────────
    // timerUrgent drives the red blink in the timer delegate.
    // Connections on ClockState rebuild the item list and force-scroll when needed.
    readonly property bool timerUrgent:
        ClockState.timerRunning && ClockState.timerLeft <= 30 && ClockState.timerLeft > 0

    Connections {
        target: ClockState

        function onTimerRunningChanged() {
            root._rebuildItems(ClockState.timerRunning ? "timer" : null)
        }

        function onSwRunningChanged() {
            root._rebuildItems(ClockState.swRunning ? "stopwatch" : null)
        }

        function onTimerLeftChanged() {
            // Force-scroll to timer the moment the last 30 seconds begin
            if (ClockState.timerRunning && ClockState.timerLeft === 30) {
                root._forceScrollTo("timer")
            }
        }
    }

    // ── Scroll debounce ───────────────────────────────────────────────────────
    property bool _scrollBusy: false
    Timer {
        id: scrollCooldown
        interval: 250
        onTriggered: root._scrollBusy = false
    }

    // ── Cava (24 bars) ────────────────────────────────────────────────────────
    readonly property int _cavaBars: 24

    property var _bars: (function() {
        var a = []; for (var i = 0; i < 24; i++) a.push(0); return a
    })()

    onIsPlayingChanged: {
        if (!isPlaying) {
            var a = []; for (var i = 0; i < 24; i++) a.push(0)
            _bars = a
        }
    }

    Process {
        id: cavaProc
        command: [
            "bash", "-c",
            "mkdir -p /tmp/brain_shell && " +
            "printf '[general]\\nbars = 24\\nframerate = 30\\nnoise_reduction = 77\\n\\n" +
            "[output]\\nmethod = raw\\nraw_target = /dev/stdout\\n" +
            "data_format = ascii\\nascii_max_range = 100\\n" +
            "bar_delimiter = 59\\nframe_delimiter = 10\\n' " +
            "> /tmp/brain_shell/cava_notch.ini && " +
            "exec cava -p /tmp/brain_shell/cava_notch.ini 2>/dev/null"
        ]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                if (!root.isPlaying) return
                var t = line.trim()
                if (t === "") return
                if (t.endsWith(";")) t = t.slice(0, -1)
                var parts = t.split(";")
                if (parts.length !== root._cavaBars) return
                var bars = []
                for (var i = 0; i < parts.length; i++)
                    bars.push(parseInt(parts[i]) || 0)
                root._bars = bars
            }
        }
    }

    // ── Carousel ──────────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        opacity: Popups.dashboardOpen ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function(event) {
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
            spacing:      15
            clip:         true
            snapMode:     ListView.SnapOneItem
            interactive:  false

            Behavior on contentY {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }

            model: root._items

            delegate: Item {
                required property string modelData
                required property int    index

                width:  Theme.cNotchMinWidth
                height: 30

                // ── Title ──────────────────────────────────────────────────────
                Text {
                    anchors.fill: parent
                    visible:      modelData === "title"
                    text:         root._appName()
                    color:        Theme.text
                    font.pixelSize: 13
                    verticalAlignment:   Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    leftPadding:  8
                    rightPadding: 8
                    elide:        Text.ElideRight
                }

                // ── Music ──────────────────────────────────────────────────────
                Item {
                    anchors.fill: parent
                    visible:      modelData === "music"

                    readonly property int artSize: 20
                    readonly property int artPad:   7

                    Item {
                        x:      parent.artPad
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
                                font.pixelSize: 9
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
                            leftMargin:  parent.artPad + parent.artSize + 5
                            right:       parent.right
                            rightMargin: 5
                            top:         parent.top
                            bottom:      parent.bottom
                        }

                        readonly property real _barW:       5
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
                                            NumberAnimation { duration: 50; easing.type: Easing.OutCubic }
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
                            leftMargin:     10
                            verticalCenter: parent.verticalCenter
                        }
                        text:           "⏱"
                        font.pixelSize: 16
                        color:          root.timerUrgent ? "#ff5555" : Theme.active
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // Time display — centered in remaining space
                    Text {
                        id: timerText
                        anchors {
                            left:           parent.left
                            leftMargin:     34
                            right:          parent.right
                            rightMargin:    8
                            verticalCenter: parent.verticalCenter
                        }
                        text:           ClockState.timerDisplay
                        font.pixelSize: 15
                        font.weight:    Font.Bold
                        font.family:    "JetBrains Mono"
                        horizontalAlignment: Text.AlignHCenter
                        color:          root.timerUrgent ? "#ff5555" : Theme.text
                        Behavior on color { ColorAnimation { duration: 200 } }

                        // Blink when urgent — opacity pulses 1 → 0.25 → 1
                        SequentialAnimation on opacity {
                            id: timerBlink
                            running:  root.timerUrgent
                            loops:    Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0;  duration: 500; easing.type: Easing.InOutSine }
                        }

                        // Snap back to full opacity when blink stops
                        Connections {
                            target: timerBlink
                            function onRunningChanged() {
                                if (!timerBlink.running) timerText.opacity = 1.0
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
                            leftMargin:     10
                            verticalCenter: parent.verticalCenter
                        }
                        text:           "⏲"
                        font.pixelSize: 16
                        color:          Theme.active
                    }

                    // Running time — centered in remaining space
                    Text {
                        anchors {
                            left:           parent.left
                            leftMargin:     34
                            right:          parent.right
                            rightMargin:    8
                            verticalCenter: parent.verticalCenter
                        }
                        text:           ClockState.swDisplay
                        font.pixelSize: 15
                        font.weight:    Font.Bold
                        font.family:    "JetBrains Mono"
                        horizontalAlignment: Text.AlignHCenter
                        color:          Theme.text
                    }
                }

            } // delegate
        }
    }

    // ── Dashboard-open indicator ──────────────────────────────────────────────
    Text {
        anchors.centerIn: parent
        text:           "▾"
        color:          Theme.active
        font.pixelSize: 14
        opacity:        Popups.dashboardOpen ? 1 : 0
        visible:        opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // ── Click to toggle dashboard ─────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            var next = !Popups.dashboardOpen
            Popups.closeAll()
            Popups.dashboardOpen = next
        }
    }
}
