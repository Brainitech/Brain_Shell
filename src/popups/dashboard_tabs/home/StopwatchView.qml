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

Item {
    id: stopwatchView

    property real localScale: 1.0
    property int pageIdx: 0
    property bool isCurrent: false
    property bool wasCurrent: false
    readonly property int myIdx: 3
    property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0

    property string swDisplay: "00:00"
    property bool swRunning: false

    signal toggleRunning()
    signal reset()

    onIsCurrentChanged: {
        if (isCurrent) {
            wasCurrent = false;
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
        if (myIdx < stopwatchView.pageIdx) return -width * parallaxFactor;
        return width;
    }

    x: targetX
    Behavior on x {
        enabled: Anim.style !== "none" && Popups.dashboardOpen
        NumberAnimation {
            duration: Anim.slow; easing.type: Anim.outExpo
            onRunningChanged: { if (!running && !stopwatchView.isCurrent) stopwatchView.wasCurrent = false; }
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
            onRunningChanged: { if (!running && !stopwatchView.isCurrent) stopwatchView.wasCurrent = false; }
        }
    }

    visible: isCurrent || wasCurrent

    Column {
        anchors.centerIn: parent
        spacing: Math.round(12 * stopwatchView.localScale)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: stopwatchView.swDisplay
            font.pixelSize: Math.round(52 * stopwatchView.localScale)
            font.weight: Font.Bold
            font.family: "JetBrains Mono"
            font.letterSpacing: Math.round(-1 * stopwatchView.localScale)
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(6 * stopwatchView.localScale)

            // Start / Stop
            Rectangle {
                width: Math.round(58 * stopwatchView.localScale); height: Math.round(26 * stopwatchView.localScale)
                radius: Math.round(8 * stopwatchView.localScale)
                color: _swStartHov.hovered
                       ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.2)
                       : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12)
                border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.fast } }

                Text {
                    anchors.centerIn: parent
                    text: stopwatchView.swRunning ? "Stop" : "Start"
                    font.pixelSize: Math.round(10 * stopwatchView.localScale); font.weight: Font.Medium
                    color: Theme.active
                }
                HoverHandler { id: _swStartHov; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: stopwatchView.toggleRunning()
                }
            }

            // Reset
            Rectangle {
                width: Math.round(58 * stopwatchView.localScale); height: Math.round(26 * stopwatchView.localScale)
                radius: Math.round(8 * stopwatchView.localScale)
                color: _swResetHov.hovered
                       ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                       : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.fast } }

                Text {
                    anchors.centerIn: parent
                    text: "Reset"
                    font.pixelSize: Math.round(10 * stopwatchView.localScale); font.weight: Font.Medium
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                }
                HoverHandler { id: _swResetHov; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: stopwatchView.reset()
                }
            }
        }
    }
}
