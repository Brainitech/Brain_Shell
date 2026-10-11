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
import "../../"
import "../../components"

Item {
    id: alarmView

    property real localScale: 1.0
    property int pageIdx: 0
    property bool isCurrent: false
    property bool wasCurrent: false
    readonly property int myIdx: 2
    property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0

    property var alarms: []
    property bool addOpen: false
    property int addHour: 7
    property int addMinute: 0

    signal addAlarm(int hour, int minute)
    signal toggleAlarm(var id)
    signal deleteAlarm(var id)

    function _zp(n) { return n < 10 ? "0" + n : "" + n }
    function resetScroll() { alarmList.contentY = 0; alarmList.returnToBounds() }

    onIsCurrentChanged: {
        if (!isCurrent) wasCurrent = true;
        else wasCurrent = false;
    }

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    clip: true

    property real targetX: {
        if (Anim.style === "none" || Anim.style === "fade" || Anim.style === "scale" || Anim.style === "rise") return 0;
        if (isCurrent) return 0;
        if (myIdx < alarmView.pageIdx) return -width * parallaxFactor;
        return width;
    }

    x: targetX
    Behavior on x {
        enabled: Anim.style !== "none"
        NumberAnimation {
            duration: Anim.slow; easing.type: Anim.outExpo
            onRunningChanged: { if (!running && !alarmView.isCurrent) alarmView.wasCurrent = false; }
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
        NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo }
    }

    scale: targetScale
    property real targetScale: {
        if (Anim.style === "scale" || Anim.style === "rise") return isCurrent ? 1.0 : 0.95;
        return 1.0;
    }
    Behavior on scale {
        enabled: Anim.style === "scale" || Anim.style === "rise"
        NumberAnimation {
            duration: Anim.slow; easing.type: Anim.outExpo
            easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod
            onRunningChanged: { if (!running && !alarmView.isCurrent) alarmView.wasCurrent = false; }
        }
    }

    visible: isCurrent || wasCurrent

    Item {
        anchors { fill: parent; margins: Math.round(10 * alarmView.localScale) }

        // ── Header — Item, not Row, so right-anchor on + button works ──
        Item {
            id: alarmHeader
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: Math.round(28 * alarmView.localScale)

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Alarms"
                font.pixelSize: Math.round(12 * alarmView.localScale)
                font.weight: Font.DemiBold
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
            }

            Item {
                id: addAlarmBtn
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: Math.round(24 * alarmView.localScale)
                height: Math.round(24 * alarmView.localScale)

                Rectangle {
                    anchors.fill: parent
                    radius: Math.round(7 * alarmView.localScale)
                    color: _addHov.hovered
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15)
                           : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                    border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.2)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: alarmView.addOpen ? "✕" : "+"
                        font.pixelSize: Math.round(14 * alarmView.localScale)
                        color: Theme.active
                    }
                }
                HoverHandler { id: _addHov; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var opening = !alarmView.addOpen
                        alarmView.addOpen = opening
                        if (opening) {
                            // Snap to next nearest 5-min mark from now
                            var d = new Date()
                            var totalMins = d.getHours() * 60 + d.getMinutes() + 1
                            var snapped   = Math.ceil(totalMins / 5) * 5
                            var h = Math.floor(snapped / 60) % 24
                            var m = snapped % 60
                            alarmView.addHour   = h
                            alarmView.addMinute = m
                            alarmTimeInput.initialize(h, m)
                        }
                    }
                }
            }
        }

        // ── Add alarm panel ────────────────────────────────────────────
        Rectangle {
            id: addPanel
            anchors {
                left: parent.left
                right: parent.right
                top: alarmHeader.bottom
                topMargin: Math.round(6 * alarmView.localScale)
            }
            height:  alarmView.addOpen ? Math.round(140 * alarmView.localScale) : 0
            clip:    true
            color:   Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.05)
            radius:  Math.round(8 * alarmView.localScale)
            border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.1)
            border.width: 1
            opacity: alarmView.addOpen ? 1 : 0
            Behavior on height  {
                NumberAnimation {
                    duration: Anim.mediumFast; easing.type: Anim.outCubic
                    easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.mediumFast
                    onRunningChanged: { if (!running && !alarmView.isCurrent) alarmView.wasCurrent = false; }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: Math.round(10 * alarmView.localScale)

                TimeInput {
                    id: alarmTimeInput
                    localScale: alarmView.localScale
                    anchors.horizontalCenter: parent.horizontalCenter
                    minuteStep: 1
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(58 * alarmView.localScale)
                    height: Math.round(26 * alarmView.localScale)
                    radius: Math.round(8 * alarmView.localScale)
                    color: _setAlarmHov.hovered
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                           : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.1)
                    border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.25)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: "Set Alarm"
                        font.pixelSize: Math.round(11 * alarmView.localScale)
                        font.weight: Font.Medium
                        color: Theme.active
                    }
                    HoverHandler { id: _setAlarmHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            alarmView.addHour   = alarmTimeInput.hours
                            alarmView.addMinute = alarmTimeInput.minutes
                            alarmView.addAlarm(alarmTimeInput.hours, alarmTimeInput.minutes)
                            alarmView.addOpen = false
                        }
                    }
                }
            }
        }

        // ── Alarm list ─────────────────────────────────────────────────
        ListView {
            id: alarmList
            anchors {
                left: parent.left
                right: parent.right
                top: addPanel.bottom
                topMargin: Math.round(6 * alarmView.localScale)
                bottom: parent.bottom
            }
            model: alarmView.alarms
            clip: true
            spacing: Math.round(4 * alarmView.localScale)
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: alarmList.width
                height: Math.round(36 * alarmView.localScale)
                radius: Math.round(8 * alarmView.localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: modelData.enabled
                              ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15)
                              : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
                border.width: 1

                // Time label
                Text {
                    anchors {
                        left: parent.left
                        leftMargin: Math.round(10 * alarmView.localScale)
                        verticalCenter: parent.verticalCenter
                    }
                    text: alarmView._zp(modelData.hour) + ":" + alarmView._zp(modelData.minute)
                    font.pixelSize: Math.round(15 * alarmView.localScale)
                    font.weight: Font.Bold
                    font.family: "JetBrains Mono"
                    color: modelData.enabled
                           ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
                           : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
                }

                // Toggle
                Rectangle {
                    id: toggleBtn
                    anchors {
                        right: deleteBtn.left
                        rightMargin: Math.round(6 * alarmView.localScale)
                        verticalCenter: parent.verticalCenter
                    }
                    width: Math.round(28 * alarmView.localScale)
                    height: Math.round(18 * alarmView.localScale)
                    radius: Math.round(9 * alarmView.localScale)
                    color: modelData.enabled
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.25)
                           : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                    Behavior on color { ColorAnimation { duration: Anim.color } }

                    Rectangle {
                        width: Math.round(12 * alarmView.localScale)
                        height: Math.round(12 * alarmView.localScale)
                        radius: Math.round(6 * alarmView.localScale)
                        anchors.verticalCenter: parent.verticalCenter
                        x: modelData.enabled ? parent.width - width - Math.round(3 * alarmView.localScale) : Math.round(3 * alarmView.localScale)
                        color: modelData.enabled ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
                        Behavior on x     {
                            NumberAnimation {
                                duration: Anim.color; easing.type: Anim.outCubic
                                easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod
                            }
                        }
                        Behavior on color { ColorAnimation { duration: Anim.color } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: alarmView.toggleAlarm(modelData.id)
                    }
                }

                // Delete
                Rectangle {
                    id: deleteBtn
                    anchors {
                        right: parent.right
                        rightMargin: Math.round(10 * alarmView.localScale)
                        verticalCenter: parent.verticalCenter
                    }
                    width: Math.round(22 * alarmView.localScale)
                    height: Math.round(22 * alarmView.localScale)
                    radius: Math.round(6 * alarmView.localScale)
                    color: _delH.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18) : "transparent"
                    Behavior on color { ColorAnimation { duration: Anim.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: Math.round(10 * alarmView.localScale)
                        color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.6)
                    }
                    HoverHandler { id: _delH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: alarmView.deleteAlarm(modelData.id)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: alarmView.alarms.length === 0 && !alarmView.addOpen
                text: "No alarms set\nTap + to add one"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Math.round(11 * alarmView.localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2)
                lineHeight: 1.5
            }
        }
    }
}
