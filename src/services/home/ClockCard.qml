/*
 * Brain Shell
 * Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import Quickshell.Io
import "../../"
import "../../components"

// ClockCard — Clock / Timer / Alarm / Stopwatch

StatCard {
    id: root
    padding: 0

    property real localScale: 1.0

    // ── Mode ──────────────────────────────────────────────────────────────────
    property string _mode: "clock"

    // ── Clock ─────────────────────────────────────────────────────────────────
    property string _hm:       "00:00"
    property string _hStr:     "00"
    property string _mStr:     "00"
    property string _sec:      "00"
    property int    _currentH: 0
    property int    _currentM: 0
    property string _amPm:     "AM"

    // ── Timer ─────────────────────────────────────────────────────────────────
    property int  _timerTotal:   10 * 60
    property int  _timerLeft:    10 * 60
    property bool _timerRunning: false
    property bool _timerStarted: false
    property bool _timerFired:   false
    property bool _addTimerOpen: false

    // ── Stopwatch ─────────────────────────────────────────────────────────────
    property int  _swMs:      0
    property bool _swRunning: false
    property bool _swStarted:   false

    // ── Alarms ────────────────────────────────────────────────────────────────
    property var  _alarms:     []
    property int  _alarmIdSeq: 0
    property bool _addOpen:    false
    property int  _addHour:    7
    property int  _addMinute:  0

    // ── Notification ─────────────────────────────────────────────────────────
    Process {
        id: notifyProc
        command: []
        running: false
    }

    function _notify(title, body) {
        notifyProc.command = ["notify-send", "-a", "Brain Shell", "-i", "alarm", title, body]
        notifyProc.running = false
        notifyProc.running = true
    }

    // ── Master tick ───────────────────────────────────────────────────────────
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            root._tick()
            if (root._swRunning) root._swMs += 1000
            if (root._timerRunning && root._timerLeft > 0) {
                root._timerLeft--
                if (root._timerLeft === 0) {
                    root._timerRunning = false
                    if (!root._timerFired) {
                        root._timerFired = true
                        root._notify("Timer finished",
                            "Your " + root._timerTotalLabel() + " timer is done.")
                    }
                }
            }
            if (root._sec === "00") root._checkAlarms()
            // Repaint ring only when on timer page and timer is running
            if (root._mode === "timer") pageTimer.requestPaint()
            root._syncState()
        }
    }

    Component.onCompleted: { _tick(); _syncState() }

    // ── Helpers ───────────────────────────────────────────────────────────────
    function _zp(n) { return n < 10 ? "0"+n : ""+n }

    function _tick() {
        var d = new Date()
        var h = d.getHours(), m = d.getMinutes(), s = d.getSeconds()
        _currentH = h; _currentM = m
        
        var displayH = PrefsService.use24HourTime ? h : (h % 12 || 12)
        
        _hm  = _zp(displayH) + ":" + _zp(m) + ":" + _zp(s)
        _hStr = _zp(displayH)
        _mStr = _zp(m)
        _sec = _zp(s)
        _amPm = h >= 12 ? "PM" : "AM"
    }

    function _timerDisplay() {
        var h = Math.floor(_timerLeft / 3600)
        var m = Math.floor((_timerLeft % 3600) / 60)
        var s = _timerLeft % 60
        return h > 0
            ? _zp(h) + ":" + _zp(m) + ":" + _zp(s)
            : _zp(m) + ":" + _zp(s)
    }

    function _timerTotalLabel() {
        var h = Math.floor(_timerTotal / 3600)
        var m = Math.floor((_timerTotal % 3600) / 60)
        return h > 0 ? h + "h " + _zp(m) + "m" : m + "m"
    }

    function _timerProgress() {
        return _timerTotal > 0 ? (_timerTotal - _timerLeft) / _timerTotal : 0
    }

    function _swDisplay() {
        var t = Math.floor(_swMs / 1000)
        return _zp(Math.floor(t / 60)) + ":" + _zp(t % 60)
    }

    function _checkAlarms() {
        var list = _alarms.slice(), changed = false
        for (var i = 0; i < list.length; i++) {
            var a = list[i]
            if (!a.enabled) continue
            if (a.hour === _currentH && a.minute === _currentM && !a.firedToday) {
                list[i] = Object.assign({}, a, { firedToday: true })
                changed = true
                _notify("Alarm", (a.label !== "" ? a.label : "Alarm") +
                        " — " + _zp(a.hour) + ":" + _zp(a.minute))
            }
            if (a.firedToday && !(a.hour === _currentH && a.minute === _currentM)) {
                list[i] = Object.assign({}, a, { firedToday: false })
                changed = true
            }
        }
        if (changed) _alarms = list
    }

    function _addAlarm(h, m) {
        var hour = (h !== undefined) ? h : _addHour
        var minute = (m !== undefined) ? m : _addMinute
        var list = _alarms.slice()
        list.push({
            id:         _alarmIdSeq++,
            hour:       hour,
            minute:     minute,
            label:      "",
            enabled:    true,
            firedToday: false
        })
        _alarms  = list
        _addOpen = false
        _syncState()
    }

    function _toggleAlarm(id) {
        var list = _alarms.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i] = Object.assign({}, list[i], { enabled: !list[i].enabled })
                break
            }
        }
        _alarms = list
        _syncState()
    }

    function _deleteAlarm(id) {
        _alarms = _alarms.filter(function(a) { return a.id !== id })
        _syncState()
    }

    function _syncState() {
        ClockState.timerRunning = _timerRunning
        ClockState.timerLeft    = _timerLeft
        ClockState.timerTotal   = _timerTotal
        ClockState.timerDisplay = _timerDisplay()
        ClockState.swRunning    = _swRunning
        ClockState.swDisplay    = _swDisplay()
        ClockState.swStarted    = _swStarted
        ClockState.timerStarted = _timerStarted

        var now = _currentH * 60 + _currentM, best = null
        for (var i = 0; i < _alarms.length; i++) {
            var a = _alarms[i]
            if (!a.enabled) continue
            var t    = a.hour * 60 + a.minute
            var diff = t >= now ? t - now : t + 1440 - now
            if (best === null || diff < best.minsUntil)
                best = { hour: a.hour, minute: a.minute, label: a.label, minsUntil: diff }
        }
        ClockState.nextAlarm = best
    }
    
    Connections {
        target: ClockState
      
        function onSwRunningChanged() {
            // Sync internal state if the singleton is changed externally (e.g., from the notch)
            if (root._swRunning !== ClockState.swRunning) {
                root._swRunning = ClockState.swRunning
            }
        }
        
        function onRequestStopwatchReset() {
            root._swMs = 0
            root._swRunning = false
            root._swStarted = false
            root._syncState()
        }
        
        function onTimerRunningChanged() {
            if (root._timerRunning !== ClockState.timerRunning) {
                root._timerRunning = ClockState.timerRunning
            }
        }
        
        function onRequestTimerReset() {
            root._timerLeft    = root._timerTotal
            root._timerRunning = false
            root._timerStarted = false
            root._syncState()
            pageTimer.requestPaint()
        }
    }
    
    Connections {
        target: PrefsService
        function onUse24HourTimeChanged() { root._tick() }
    }
    
    // ── UI ────────────────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        Item {
            id: pagesContainer
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: tabs.top }
            clip: true
            
            property int pageIdx: Math.max(0, ["clock", "timer", "alarm", "stopwatch"].indexOf(root._mode))

            // ── CLOCK ─────────────────────────────────────────────────────────────
            Item {
                id: pageClock
                readonly property int myIdx: 0
                property bool isCurrent: root._mode === "clock"
                property bool wasCurrent: false
                property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                onIsCurrentChanged: { 
                    if (isCurrent) wasCurrent = false;
                    else if (Anim.style === "none") wasCurrent = false;
                    else wasCurrent = true;
                }
                
                width: parent.width; height: parent.height
                
                property real targetX: {
                    if (Anim.style === "none" || Anim.style === "fade" || Anim.style === "scale" || Anim.style === "rise") return 0;
                    if (isCurrent) return 0;
                    if (myIdx < pagesContainer.pageIdx) return -width * parallaxFactor;
                    return width;
                }
                
                x: targetX
                Behavior on x {
                    enabled: Anim.style !== "none"
                    NumberAnimation { 
                        duration: Anim.slow; easing.type: Anim.outExpo
                        onRunningChanged: { if (!running && !pageClock.isCurrent) pageClock.wasCurrent = false; }
                    }
                }
                
                property real targetOpacity: {
                    if (Anim.style === "none" || Anim.style === "slide") return 1.0;
                    if (isCurrent) return 1.0;
                    return 0.0;
                }
                opacity: targetOpacity
                Behavior on opacity {
                    enabled: Anim.style !== "none" && Anim.style !== "slide"
                    NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo
                        onRunningChanged: { if (!running && !pageClock.isCurrent) pageClock.wasCurrent = false; } }
                }
                
                scale: targetScale
                property real targetScale: {
                    if (Anim.style === "scale" || Anim.style === "rise") return isCurrent ? 1.0 : 0.95;
                    return 1.0;
                }
                Behavior on scale {
                    enabled: Anim.style === "scale" || Anim.style === "rise"
                    NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod
                        onRunningChanged: { if (!running && !pageClock.isCurrent) pageClock.wasCurrent = false; } }
                }
                
                visible: isCurrent || wasCurrent

                Row {
                    anchors.centerIn: parent
                    spacing: Math.round(10 * localScale)

                    // HH stacked above MM with diagonal offset
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        // Width fits both texts plus the one-char offset
                        readonly property int charOffset: Math.round(40 * localScale)
                        width:  hhText.implicitWidth + charOffset
                        height: hhText.implicitHeight + mmText.implicitHeight - Math.round(8 * localScale)

                        Text {
                            id: hhText
                            anchors.left: parent.left
                            anchors.top:  parent.top
                            text: root._hStr
                            font.pixelSize: Math.round(72 * localScale); font.weight: Font.Bold
                            font.family: "JetBrains Mono"; font.letterSpacing: Math.round(-4 * localScale)
                            color: Theme.text
                        }
                        Text {
                            id: mmText
                            anchors.left: parent.left
                            anchors.leftMargin: parent.charOffset
                            anchors.top:  hhText.bottom
                            anchors.topMargin: Math.round(-8 * localScale)
                            text: root._mStr
                            font.pixelSize: Math.round(72 * localScale); font.weight: Font.Bold
                            font.family: "JetBrains Mono"; font.letterSpacing: Math.round(-4 * localScale)
                            color: Theme.active
                        }
                    }

                    // Seconds and AM/PM
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(4 * localScale)
                        
                        Text {
                            text: root._sec
                            font.pixelSize: Math.round(22 * localScale); font.weight: Font.Medium
                            font.family: "JetBrains Mono"
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                        }
                        
                        Text {
                            visible: !PrefsService.use24HourTime
                            text: root._amPm
                            font.pixelSize: Math.round(14 * localScale); font.weight: Font.Bold
                            font.family: "JetBrains Mono"
                            color: Theme.active
                        }
                    }
                }
            }

            // ── TIMER ─────────────────────────────────────────────────────────────
            TimerView {
                id: pageTimer
                localScale: root.localScale
                pageIdx: pagesContainer.pageIdx
                isCurrent: root._mode === "timer"
                timerTotal: root._timerTotal
                timerLeft: root._timerLeft
                timerRunning: root._timerRunning
                timerDisplay: root._timerDisplay()
                timerProgress: root._timerProgress()
                addTimerOpen: root._addTimerOpen
                onAddTimerOpenChanged: root._addTimerOpen = addTimerOpen
                onSetTimer: function(total) {
                    root._timerTotal   = total
                    root._timerLeft    = total
                    root._timerRunning = false
                    root._timerFired   = false
                    root._syncState()
                    pageTimer.requestPaint()
                }
                onToggleRunning: {
                    root._timerRunning = !root._timerRunning
                    root._timerStarted = true
                    root._timerFired   = false
                    root._syncState()
                }
                onReset: {
                    root._timerLeft    = root._timerTotal
                    root._timerRunning = false
                    root._timerFired   = false
                    root._timerStarted = false
                    root._syncState()
                    pageTimer.requestPaint()
                }
            }

            // ── ALARM ─────────────────────────────────────────────────────────────
            AlarmView {
                id: pageAlarm
                localScale: root.localScale
                pageIdx: pagesContainer.pageIdx
                isCurrent: root._mode === "alarm"
                alarms: root._alarms
                addOpen: root._addOpen
                onAddOpenChanged: root._addOpen = addOpen
                onAddAlarm: function(h, m) {
                    root._addHour   = h
                    root._addMinute = m
                    root._addAlarm(h, m)
                }
                onToggleAlarm: function(id) {
                    root._toggleAlarm(id)
                }
                onDeleteAlarm: function(id) {
                    root._deleteAlarm(id)
                }
            }

            // ── STOPWATCH ─────────────────────────────────────────────────────────
            StopwatchView {
                id: pageStopwatch
                localScale: root.localScale
                pageIdx: pagesContainer.pageIdx
                isCurrent: root._mode === "stopwatch"
                swDisplay: root._swDisplay()
                swRunning: root._swRunning
                onToggleRunning: {
                    root._swRunning = !root._swRunning
                    root._swStarted = true
                    root._syncState()
                }
                onReset: {
                    root._swMs = 0
                    root._swRunning = false
                    root._swStarted = false
                    root._syncState()
                }
            }
        } // End of pagesContainer

        // ── Tab bar ───────────────────────────────────────────────────────────
        TabSwitcher {
            id: tabs
            localScale: root.localScale
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
