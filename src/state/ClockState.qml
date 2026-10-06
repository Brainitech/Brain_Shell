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

// ClockState — exposes active clock module state for the dynamic island.
// Written by ClockCard, read by CenterNotch / dynamic island.

QtObject {
    // Timer
    property bool   timerRunning: false
    property bool   timerStarted:   false
    property int    timerLeft:    0
    property int    timerTotal:   0
    property string timerDisplay: "00:00"

    // Stopwatch
    property bool   swRunning: false
    property bool   swStarted:   false
    property string swDisplay: "00:00"
    
    signal requestStopwatchReset()
    signal requestTimerReset()

    // Alarms — list of { id, hour, minute, label, enabled }

    // Nearest upcoming enabled alarm: { hour, minute, label, minsUntil } or null
    property var nextAlarm: null

    // True when something is actively running
    readonly property bool hasActiveEvent:
        timerRunning || swRunning || nextAlarm !== null
}
