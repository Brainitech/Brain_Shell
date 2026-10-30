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
import "../"

// TimeInput — reusable HH:MM[:SS] input
// Props : hours (int, readonly), minutes (int, readonly), seconds (int, readonly)
//         showSeconds (bool, default false)
//         minuteStep (int, default 1), secondStep (int, default 1)
// Call  : initialize(h, m, s) to push values from outside

Item {
    id: root

    property real localScale: 1.0

    readonly property int hours:   hVal
    readonly property int minutes: mVal
    readonly property int seconds: sVal

    property bool showSeconds: false
    property int minuteStep: 1
    property int secondStep: 1
    property int hVal: 0
    property int mVal: 0
    property int sVal: 0

    function initialize(h, m, s) {
        hVal = h !== undefined ? h : 0
        mVal = m !== undefined ? m : 0
        sVal = s !== undefined ? s : 0
    }

    function zp(n)  { var s = "" + n; return s.length < 2 ? "0" + s : s }
    function incH() { hVal = hVal >= 23 ? 0  : hVal + 1 }
    function decH() { hVal = hVal <= 0  ? 23 : hVal - 1 }
    function incM() { var n = mVal + minuteStep; mVal = n > 59 ? 0 : n }
    function decM() { var n = mVal - minuteStep; mVal = n < 0 ? Math.floor(59 / minuteStep) * minuteStep : n }
    function incS() { var n = sVal + secondStep; sVal = n > 59 ? 0 : n }
    function decS() { var n = sVal - secondStep; sVal = n < 0 ? Math.floor(59 / secondStep) * secondStep : n }

    implicitWidth:  _row.implicitWidth
    implicitHeight: _row.implicitHeight

    Row {
        id: _row
        spacing: Math.round(8 * localScale)

        // ══ HOURS ═════════════════════════════════════════════════════════════
        Column {
            spacing: Math.round(2 * localScale)
            width: Math.round(36 * localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "HH"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Medium
                font.family: "JetBrains Mono"
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
            }

            Rectangle {
                width: parent.width; height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: hUpH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.superFast} }
                Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) }
                HoverHandler { id: hUpH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root.incH() }
            }

            Item {
                width: parent.width; height: Math.round(30 * localScale)

                Text {
                    anchors.centerIn: parent
                    text: root.zp(root.hVal)
                    font.pixelSize: Math.round(20 * localScale); font.weight: Font.Bold
                    font.family: "JetBrains Mono"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(ev) {
                        ev.accepted = true
                        if (ev.angleDelta.y > 0) root.incH()
                        else                     root.decH()
                    }
                }
            }

            Rectangle {
                width: parent.width; height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: hDnH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.superFast} }
                Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) }
                HoverHandler { id: hDnH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root.decH() }
            }
        }

        // Colon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Math.round(8 * localScale)
            text: ":"
            font.pixelSize: Math.round(22 * localScale); font.weight: Font.Bold
            font.family: "JetBrains Mono"
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
        }

        // ══ MINUTES ═══════════════════════════════════════════════════════════
        Column {
            spacing: Math.round(2 * localScale)
            width: Math.round(36 * localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "MM"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Medium
                font.family: "JetBrains Mono"
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
            }

            Rectangle {
                width: parent.width; height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: mUpH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.superFast} }
                Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) }
                HoverHandler { id: mUpH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root.incM() }
            }

            Item {
                width: parent.width; height: Math.round(30 * localScale)

                Text {
                    anchors.centerIn: parent
                    text: root.zp(root.mVal)
                    font.pixelSize: Math.round(20 * localScale); font.weight: Font.Bold
                    font.family: "JetBrains Mono"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(ev) {
                        ev.accepted = true
                        if (ev.angleDelta.y > 0) root.incM()
                        else                     root.decM()
                    }
                }
            }

            Rectangle {
                width: parent.width; height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: mDnH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.superFast} }
                Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) }
                HoverHandler { id: mDnH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root.decM() }
            }
        }

        // Colon (Seconds)
        Text {
            visible: root.showSeconds
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Math.round(8 * localScale)
            text: ":"
            font.pixelSize: Math.round(22 * localScale); font.weight: Font.Bold
            font.family: "JetBrains Mono"
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
        }

        // ══ SECONDS ═══════════════════════════════════════════════════════════
        Column {
            visible: root.showSeconds
            spacing: Math.round(2 * localScale)
            width: Math.round(36 * localScale)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SS"; font.pixelSize: Math.round(9 * localScale); font.weight: Font.Medium
                font.family: "JetBrains Mono"
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
            }

            Rectangle {
                width: parent.width; height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: sUpH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.superFast} }
                Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) }
                HoverHandler { id: sUpH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root.incS() }
            }

            Item {
                width: parent.width; height: Math.round(30 * localScale)

                Text {
                    anchors.centerIn: parent
                    text: root.zp(root.sVal)
                    font.pixelSize: Math.round(20 * localScale); font.weight: Font.Bold
                    font.family: "JetBrains Mono"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(ev) {
                        ev.accepted = true
                        if (ev.angleDelta.y > 0) root.incS()
                        else                     root.decS()
                    }
                }
            }

            Rectangle {
                width: parent.width; height: Math.round(22 * localScale); radius: Math.round(6 * localScale)
                color: sDnH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08); border.width: 1
                Behavior on color { ColorAnimation { duration: Anim.superFast} }
                Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: Math.round(9 * localScale); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) }
                HoverHandler { id: sDnH; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: root.decS() }
            }
        }
    }
}
