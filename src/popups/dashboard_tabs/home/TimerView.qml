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
import "../../../"
import "../../../components"

Item {
    id: timerView

    property real localScale: 1.0
    property int pageIdx: 0
    property bool isCurrent: false
    property bool wasCurrent: false
    readonly property int myIdx: 1
    property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0

    property int timerTotal: 600
    property int timerLeft: 600
    property bool timerRunning: false
    property string timerDisplay: "10:00"
    property real timerProgress: 0.0
    property bool addTimerOpen: false

    signal setTimer(int totalSeconds)
    signal toggleRunning()
    signal reset()

    function requestPaint() {
        if (timerCanvas) timerCanvas.requestPaint()
    }

    onTimerProgressChanged: requestPaint()

    onIsCurrentChanged: {
        if (isCurrent) {
            wasCurrent = false;
            requestPaint();
        } else if (Anim.style === "none" || !Popups.dashboardOpen) {
            wasCurrent = false;
        } else {
            wasCurrent = true;
        }
    }

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0

    property real targetX: {
        if (Anim.style === "none" || Anim.style === "fade" || Anim.style === "scale" || Anim.style === "rise") return 0;
        if (isCurrent) return 0;
        if (myIdx < timerView.pageIdx) return -width * parallaxFactor;
        return width;
    }

    x: targetX
    Behavior on x {
        enabled: Anim.style !== "none" && Popups.dashboardOpen
        NumberAnimation {
            duration: Anim.slow; easing.type: Anim.outExpo
            onRunningChanged: { if (!running && !timerView.isCurrent) timerView.wasCurrent = false; }
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
        NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo }
    }

    scale: targetScale
    property real targetScale: {
        if (Anim.style === "scale" || Anim.style === "rise") return isCurrent ? 1.0 : 0.95;
        return 1.0;
    }
    Behavior on scale {
        enabled: (Anim.style === "scale" || Anim.style === "rise") && Popups.dashboardOpen
        NumberAnimation {
            duration: Anim.slow; easing.type: Anim.outExpo
            easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod
            onRunningChanged: { if (!running && !timerView.isCurrent) timerView.wasCurrent = false; }
        }
    }

    visible: isCurrent || wasCurrent

    // "+" / "x" toggle — top-right corner
    Item {
        id: addTimerBtn
        anchors {
            top: parent.top
            right: parent.right
            topMargin: Math.round(8 * timerView.localScale)
            rightMargin: Math.round(8 * timerView.localScale)
        }
        width: Math.round(24 * timerView.localScale)
        height: Math.round(24 * timerView.localScale)

        Rectangle {
            anchors.fill: parent
            radius: Math.round(7 * timerView.localScale)
            color: _addTimerHov.hovered
                   ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.15)
                   : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
            border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.2)
            border.width: 1
            Behavior on color { ColorAnimation { duration: Anim.fast } }

            Text {
                anchors.centerIn: parent
                text: timerView.addTimerOpen ? "x" : "+"
                font.pixelSize: Math.round(14 * timerView.localScale)
                color: Theme.active
            }
        }
        HoverHandler { id: _addTimerHov; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            onClicked: timerView.addTimerOpen = !timerView.addTimerOpen
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: Math.round(10 * timerView.localScale)

        // ── Ring — hidden while add-timer panel is open ────────────────
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(100 * timerView.localScale)
            height: Math.round(100 * timerView.localScale)
            visible: !timerView.addTimerOpen

            Canvas {
                id: timerCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2, cy = height / 2, r = Math.round(44 * timerView.localScale)
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.strokeStyle = Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                    ctx.lineWidth = Math.round(5 * timerView.localScale); ctx.stroke()
                    var p = timerView.timerProgress
                    if (p > 0) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p)
                        ctx.strokeStyle = Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.85)
                        ctx.lineWidth = Math.round(5 * timerView.localScale); ctx.lineCap = "round"; ctx.stroke()
                    }
                }
                Connections {
                    target: Theme
                    function onActiveChanged() { timerCanvas.requestPaint() }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 1

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: timerView.timerDisplay
                    font.pixelSize: timerView.timerLeft >= 3600 ? Math.round(16 * timerView.localScale) : Math.round(22 * timerView.localScale)
                    font.weight: Font.Bold
                    font.family: "JetBrains Mono"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "remaining"
                    font.pixelSize: Math.round(8 * timerView.localScale)
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                }
            }
        }

        // ── Presets — hidden while add-timer panel is open ─────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(5 * timerView.localScale)
            visible: !timerView.addTimerOpen && !timerView.timerRunning

            Repeater {
                model: [5, 10, 15, 30]
                delegate: Rectangle {
                    required property int modelData
                    required property int index

                    width: Math.round(36 * timerView.localScale)
                    height: Math.round(22 * timerView.localScale)
                    radius: Math.round(6 * timerView.localScale)
                    color: _pH.hovered
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.1)
                           : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData < 60 ? modelData + "m" : "1h"
                        font.pixelSize: Math.round(9 * timerView.localScale)
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                    }
                    HoverHandler { id: _pH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: timerView.setTimer(modelData * 60)
                    }
                }
            }
        }

        // ── Custom duration — visible only when add-timer panel is open
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: timerView.addTimerOpen
            width: _timerInputCol.implicitWidth
            height: _timerInputCol.implicitHeight

            Column {
                id: _timerInputCol
                anchors.centerIn: parent
                spacing: Math.round(10 * timerView.localScale)

                TimeInput {
                    id: timerTimeInput
                    localScale: timerView.localScale
                    anchors.horizontalCenter: parent.horizontalCenter
                    showSeconds: true
                    minuteStep: 1
                    secondStep: 1
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(58 * timerView.localScale)
                    height: Math.round(26 * timerView.localScale)
                    radius: Math.round(8 * timerView.localScale)
                    color: _setTimerHov.hovered
                           ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
                           : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.1)
                    border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.25)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Anim.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: "Set Timer"
                        font.pixelSize: Math.round(11 * timerView.localScale)
                        font.weight: Font.Medium
                        color: Theme.active
                    }
                    HoverHandler { id: _setTimerHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var total = timerTimeInput.hours * 3600 + timerTimeInput.minutes * 60 + timerTimeInput.seconds
                            timerView.addTimerOpen = false
                            if (total > 0) {
                                timerView.setTimer(total)
                            }
                        }
                    }
                }
            }
        }

        // ── Start / Pause + Reset ─────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(6 * timerView.localScale)
            visible: !timerView.addTimerOpen

            // Start / Pause
            Rectangle {
                width: Math.round(58 * timerView.localScale)
                height: Math.round(26 * timerView.localScale)
                radius: Math.round(8 * timerView.localScale)
                color: _startHov.hovered
                       ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.2)
                       : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12)
                border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22)
                border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.fast } }

                Text {
                    anchors.centerIn: parent
                    text: timerView.timerRunning ? "Pause" : "Start"
                    font.pixelSize: Math.round(10 * timerView.localScale)
                    font.weight: Font.Medium
                    color: Theme.active
                }
                HoverHandler { id: _startHov; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: timerView.toggleRunning()
                }
            }

            // Reset
            Rectangle {
                width: Math.round(58 * timerView.localScale)
                height: Math.round(26 * timerView.localScale)
                radius: Math.round(8 * timerView.localScale)
                color: _resetHov.hovered
                       ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                       : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.fast } }

                Text {
                    anchors.centerIn: parent
                    text: "Reset"
                    font.pixelSize: Math.round(10 * timerView.localScale)
                    font.weight: Font.Medium
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                }
                HoverHandler { id: _resetHov; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: timerView.reset()
                }
            }
        }
    }
}
