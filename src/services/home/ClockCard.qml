import QtQuick
import "../../"
import "../../components"

// Clock card — four modes: Clock, Timer, Alarm, Stopwatch.
// TabSwitcher pinned to the bottom edge.
// Self-contained: owns all time/timer/stopwatch state.

StatCard {
    id: root
    padding: 0

    // ── State ─────────────────────────────────────────────────────────────────
    property string _mode: "clock"

    // Clock
    property string _hm:   "00:00"
    property string _sec:  "00"
    property string _ampm: "AM"

    // Timer
    property int  _timerTotal:   25 * 60
    property int  _timerLeft:    25 * 60
    property bool _timerRunning: false

    // Stopwatch
    property int  _swMs:      0
    property bool _swRunning: false

    // ── Master tick ───────────────────────────────────────────────────────────
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            root._tick()
            if (root._swRunning) root._swMs += 1000
            if (root._timerRunning && root._timerLeft > 0) {
                root._timerLeft--
                if (root._timerLeft === 0) root._timerRunning = false
            }
        }
    }

    Component.onCompleted: _tick()

    // ── Helpers ───────────────────────────────────────────────────────────────
    function _zp(n) { return n < 10 ? "0"+n : ""+n }

    function _tick() {
        var d = new Date(); var h = d.getHours(); var m = d.getMinutes(); var s = d.getSeconds()
        var pm = h >= 12; var h12 = h % 12; if (h12 === 0) h12 = 12
        _hm   = _zp(h12) + ":" + _zp(m)
        _sec  = _zp(s)
        _ampm = pm ? "PM" : "AM"
    }

    function _timerDisplay() {
        return _zp(Math.floor(_timerLeft / 60)) + ":" + _zp(_timerLeft % 60)
    }
    function _timerProgress() {
        return _timerTotal > 0 ? (_timerTotal - _timerLeft) / _timerTotal : 0
    }
    function _swDisplay() {
        var t = Math.floor(_swMs / 1000)
        return _zp(Math.floor(t / 60)) + ":" + _zp(t % 60)
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        // ── CLOCK ─────────────────────────────────────────────────────────────
        Item {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: tabs.top }
            visible: root._mode === "clock"
            Column {
                anchors.centerIn: parent; spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root._hm; font.pixelSize: 72; font.weight: Font.Bold
                    font.family: "JetBrains Mono"; font.letterSpacing: -3
                    color: Qt.rgba(235/255,240/255,255/255,1); lineHeight: 1
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ":" + root._sec; font.pixelSize: 20; font.family: "JetBrains Mono"
                        color: Qt.rgba(166/255,208/255,247/255,0.45)
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root._ampm; font.pixelSize: 11; font.weight: Font.Bold
                        font.letterSpacing: 2; color: Qt.rgba(166/255,208/255,247/255,0.5)
                    }
                }
            }
        }

        // ── TIMER ─────────────────────────────────────────────────────────────
        Item {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: tabs.top }
            visible: root._mode === "timer"
            Column {
                anchors.centerIn: parent; spacing: 10

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 100; height: 100

                    Canvas {
                        id: timerCanvas; anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var cx = width/2, cy = height/2, r = 44
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2)
                            ctx.strokeStyle = Qt.rgba(1,1,1,0.08); ctx.lineWidth = 5; ctx.stroke()
                            var p = root._timerProgress()
                            if (p > 0) {
                                ctx.beginPath()
                                ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + Math.PI*2*p)
                                ctx.strokeStyle = Qt.rgba(166/255,208/255,247/255,0.85)
                                ctx.lineWidth = 5; ctx.lineCap = "round"; ctx.stroke()
                            }
                        }
                        Connections {
                            target: root
                            function on_TimerLeftChanged() { timerCanvas.requestPaint() }
                        }
                    }
                    Column {
                        anchors.centerIn: parent; spacing: 1
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root._timerDisplay(); font.pixelSize: 22; font.weight: Font.Bold
                            font.family: "JetBrains Mono"; color: Qt.rgba(235/255,240/255,255/255,0.9)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "remaining"; font.pixelSize: 8; color: Qt.rgba(1,1,1,0.25)
                        }
                    }
                }

                // Presets
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 5
                    Repeater {
                        model: [5, 15, 25, 60]
                        delegate: Rectangle {
                            required property var modelData; required property int index
                            width: 36; height: 22; radius: 6
                            color: pH.hovered ? Qt.rgba(166/255,208/255,247/255,0.1) : Qt.rgba(1,1,1,0.05)
                            border.color: Qt.rgba(1,1,1,0.1); border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData < 60 ? modelData+"m" : "1h"
                                font.pixelSize: 9; font.family: "JetBrains Mono"; font.weight: Font.Bold
                                color: Qt.rgba(1,1,1,0.45)
                            }
                            HoverHandler { id: pH; cursorShape: Qt.PointingHandCursor }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root._timerTotal   = modelData * 60
                                    root._timerLeft    = modelData * 60
                                    root._timerRunning = false
                                }
                            }
                        }
                    }
                }

                // Start/Pause + Reset
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                    Repeater {
                        model: [
                            { label: root._timerRunning ? "Pause" : "Start", primary: true  },
                            { label: "Reset",                                 primary: false }
                        ]
                        delegate: Rectangle {
                            required property var modelData; required property int index
                            width: 58; height: 26; radius: 8
                            color: modelData.primary ? Qt.rgba(166/255,208/255,247/255,0.12) : Qt.rgba(1,1,1,0.05)
                            border.color: modelData.primary ? Qt.rgba(166/255,208/255,247/255,0.22) : Qt.rgba(1,1,1,0.1)
                            border.width: 1
                            Text { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 10; font.weight: Font.Medium; color: modelData.primary ? Theme.active : Qt.rgba(1,1,1,0.4) }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData.primary) root._timerRunning = !root._timerRunning
                                    else { root._timerLeft = root._timerTotal; root._timerRunning = false }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── ALARM ─────────────────────────────────────────────────────────────
        Item {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: tabs.top }
            visible: root._mode === "alarm"
            Column {
                anchors.centerIn: parent; spacing: 8
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰀠"; font.pixelSize: 36; color: Qt.rgba(166/255,208/255,247/255,0.3) }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No alarms set"; font.pixelSize: 13; font.weight: Font.Medium; color: Qt.rgba(1,1,1,0.3) }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Coming soon"; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.18) }
            }
        }

        // ── STOPWATCH ─────────────────────────────────────────────────────────
        Item {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: tabs.top }
            visible: root._mode === "stopwatch"
            Column {
                anchors.centerIn: parent; spacing: 12
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root._swDisplay(); font.pixelSize: 52; font.weight: Font.Bold
                    font.family: "JetBrains Mono"; font.letterSpacing: -1
                    color: Qt.rgba(235/255,240/255,255/255,0.9)
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                    Repeater {
                        model: [
                            { label: root._swRunning ? "Stop" : "Start", primary: true  },
                            { label: "Reset",                             primary: false }
                        ]
                        delegate: Rectangle {
                            required property var modelData; required property int index
                            width: 58; height: 26; radius: 8
                            color: modelData.primary ? Qt.rgba(166/255,208/255,247/255,0.12) : Qt.rgba(1,1,1,0.05)
                            border.color: modelData.primary ? Qt.rgba(166/255,208/255,247/255,0.22) : Qt.rgba(1,1,1,0.1)
                            border.width: 1
                            Text { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 10; font.weight: Font.Medium; color: modelData.primary ? Theme.active : Qt.rgba(1,1,1,0.4) }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData.primary) root._swRunning = !root._swRunning
                                    else { root._swMs = 0; root._swRunning = false }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Tab bar — bottom ──────────────────────────────────────────────────
        TabSwitcher {
            id: tabs
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            orientation: "horizontal"; width: parent.width
            currentPage: root._mode
            model: [
                { key: "clock",     icon: "󰥔", label: "Clock"     },
                { key: "timer",     icon: "󱎫", label: "Timer"     },
                { key: "alarm",     icon: "󰀠", label: "Alarm"     },
                { key: "stopwatch", icon: "󰔚", label: "Stopwatch" }
            ]
            onPageChanged: function(key) { root._mode = key }
        }
    }
}
