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

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../state"

QtObject {
    id: root

    property var alarms:     []
    property int alarmIdSeq: 0

    function _zp(n) { return n < 10 ? "0" + n : "" + n }

    property var notifyProc: Process {
        command: []
        running: false
    }

    function _notify(title, body) {
        notifyProc.command = ["notify-send", "-a", "Brain Shell", "-i", "alarm", title, body]
        notifyProc.running = false
        notifyProc.running = true
    }

    function addAlarm(hour, minute, label) {
        var list = alarms.slice()
        list.push({
            id:         alarmIdSeq++,
            hour:       hour,
            minute:     minute,
            label:      label || "",
            enabled:    true,
            firedToday: false
        })
        alarms = list
        updateNextAlarm()
    }

    function toggleAlarm(id) {
        var list = alarms.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i] = Object.assign({}, list[i], { enabled: !list[i].enabled })
                break
            }
        }
        alarms = list
        updateNextAlarm()
    }

    function deleteAlarm(id) {
        alarms = alarms.filter(function(a) { return a.id !== id })
        updateNextAlarm()
    }

    function checkAlarms() {
        var d = new Date()
        var currentH = d.getHours()
        var currentM = d.getMinutes()
        var list = alarms.slice()
        var changed = false

        for (var i = 0; i < list.length; i++) {
            var a = list[i]
            if (!a.enabled) continue
            if (a.hour === currentH && a.minute === currentM && !a.firedToday) {
                list[i] = Object.assign({}, a, { firedToday: true })
                changed = true
                _notify("Alarm", (a.label !== "" ? a.label : "Alarm") +
                        " — " + _zp(a.hour) + ":" + _zp(a.minute))
            }
            if (a.firedToday && !(a.hour === currentH && a.minute === currentM)) {
                list[i] = Object.assign({}, a, { firedToday: false })
                changed = true
            }
        }
        if (changed) alarms = list
        updateNextAlarm(currentH, currentM)
    }

    function updateNextAlarm(currentH, currentM) {
        if (currentH === undefined || currentM === undefined) {
            var d = new Date()
            currentH = d.getHours()
            currentM = d.getMinutes()
        }
        var now = currentH * 60 + currentM
        var best = null

        for (var i = 0; i < alarms.length; i++) {
            var a = alarms[i]
            if (!a.enabled) continue
            var t    = a.hour * 60 + a.minute
            var diff = t >= now ? t - now : t + 1440 - now
            if (best === null || diff < best.minsUntil)
                best = { hour: a.hour, minute: a.minute, label: a.label, minsUntil: diff }
        }
        ClockState.nextAlarm = best
    }

    property int _lastM: -1
    property var tickTimer: Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            var m = new Date().getMinutes()
            if (m !== root._lastM) {
                root._lastM = m
                root.checkAlarms()
            }
        }
    }

    Component.onCompleted: {
        root._lastM = new Date().getMinutes()
        updateNextAlarm()
    }
}
