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
import "../"

// ClockCard — Clock / Timer / Alarm / Stopwatch view shell

StatCard {
    id: root
    padding: 0

    property real localScale: 1.0

    // ── Mode ──────────────────────────────────────────────────────────────────
    property string _mode: ClockState.activeMode

    // ── Clock ─────────────────────────────────────────────────────────────────
    property string _hStr:     "00"
    property string _mStr:     "00"
    property string _sec:      "00"
    property string _amPm:     "AM"

    // ── View Dialog States ────────────────────────────────────────────────────
    property bool _addTimerOpen: false
    property bool _addOpen:      false
    property int  _addHour:      7
    property int  _addMinute:    0

    function _zp(n) { return n < 10 ? "0" + n : "" + n }

    function _tick() {
        var d = new Date()
        var h = d.getHours(), m = d.getMinutes(), s = d.getSeconds()
        var displayH = PrefsService.use24HourTime ? h : (h % 12 || 12)
        _hStr = _zp(displayH)
        _mStr = _zp(m)
        _sec = _zp(s)
        _amPm = h >= 12 ? "PM" : "AM"
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: root._tick()
    }

    Component.onCompleted: _tick()

    Connections {
        target: PrefsService
        function onUse24HourTimeChanged() { root._tick() }
    }

    function resetCard() {
        root._mode = "clock"
        ClockState.activeMode = "clock"
        root._addOpen = false
        root._addTimerOpen = false
        if (pageAlarm && pageAlarm.resetScroll) pageAlarm.resetScroll()
    }

    Connections {
        target: ClockState
        function onActiveModeChanged() {
            root._mode = ClockState.activeMode
        }
    }

    Connections {
        target: SurfaceState
        function onActiveContentChanged() {
            if (SurfaceState.activeContent !== "dashboard") root.resetCard()
        }
    }

    Connections {
        target: Popups
        function onDashboardPageChanged() {
            if (Popups.dashboardPage !== "home") root.resetCard()
        }
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
                    else if (Anim.style === "none" || !Popups.dashboardOpen) wasCurrent = false;
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
                    enabled: Anim.style !== "none" && Popups.dashboardOpen
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
                    enabled: Anim.style !== "none" && Anim.style !== "slide" && Popups.dashboardOpen
                    NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo
                        onRunningChanged: { if (!running && !pageClock.isCurrent) pageClock.wasCurrent = false; } }
                }

                scale: targetScale
                property real targetScale: {
                    if (Anim.style === "scale" || Anim.style === "rise") return isCurrent ? 1.0 : 0.95;
                    return 1.0;
                }
                Behavior on scale {
                    enabled: (Anim.style === "scale" || Anim.style === "rise") && Popups.dashboardOpen
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
                timerTotal: TimerService.total
                timerLeft: TimerService.left
                timerRunning: TimerService.running
                timerDisplay: TimerService.display
                timerProgress: TimerService.progress
                addTimerOpen: root._addTimerOpen
                onAddTimerOpenChanged: root._addTimerOpen = addTimerOpen
                onSetTimer: function(total) {
                    TimerService.setTimer(total)
                    pageTimer.requestPaint()
                }
                onToggleRunning: {
                    TimerService.toggleRunning()
                }
                onReset: {
                    TimerService.reset()
                    pageTimer.requestPaint()
                }
            }

            // ── ALARM ─────────────────────────────────────────────────────────────
            AlarmView {
                id: pageAlarm
                localScale: root.localScale
                pageIdx: pagesContainer.pageIdx
                isCurrent: root._mode === "alarm"
                alarms: AlarmService.alarms
                addOpen: root._addOpen
                onAddOpenChanged: root._addOpen = addOpen
                onAddAlarm: function(h, m) {
                    root._addHour   = h
                    root._addMinute = m
                    AlarmService.addAlarm(h, m)
                    root._addOpen = false
                }
                onToggleAlarm: function(id) {
                    AlarmService.toggleAlarm(id)
                }
                onDeleteAlarm: function(id) {
                    AlarmService.deleteAlarm(id)
                }
            }

            // ── STOPWATCH ─────────────────────────────────────────────────────────
            StopwatchView {
                id: pageStopwatch
                localScale: root.localScale
                pageIdx: pagesContainer.pageIdx
                isCurrent: root._mode === "stopwatch"
                swDisplay: StopwatchService.display
                swRunning: StopwatchService.running
                onToggleRunning: {
                    StopwatchService.toggleRunning()
                }
                onReset: {
                    StopwatchService.reset()
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
            onPageChanged: function(key) {
                root._mode = key
                ClockState.activeMode = key
            }
        }
    }
}
