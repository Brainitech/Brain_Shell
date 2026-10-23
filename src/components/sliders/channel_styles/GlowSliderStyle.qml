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
import Quickshell
import "../../../"

Item {
    id: col
    property real localScale: 1.0
    property string label: ""
    property string icon: ""
    property real value: 0.0
    property bool muted: false
    property bool active: false
    property color accent: Theme.active

    readonly property int trackHeight: Math.round(170 * localScale)
    readonly property int barW: Math.round(14 * localScale)
    readonly property int dotD: Math.round(16 * localScale)

    signal volumeChanged(real value)
    signal muteToggled()

    implicitWidth: Math.max(Math.round(56 * localScale), inner.implicitWidth)
    implicitHeight: inner.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Column {
        id: inner
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Math.round(14 * localScale)

        // Percentage
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: col.active ? Math.round(col.value * 100) + "%" : "--%"
            font.pixelSize: Math.round(15 * localScale)
            font.weight: Font.Bold
            font.family: "JetBrains Mono"
            color: col.muted
                   ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                   : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35 + col.value * 0.65)
            Behavior on color { ColorAnimation { duration: Anim.fast } }
        }

        // Track
        Item {
            id: trackArea
            anchors.horizontalCenter: parent.horizontalCenter
            width: col.dotD
            height: col.trackHeight + col.dotD

            Rectangle {
                id: track
                anchors.fill: parent
                anchors.topMargin: col.dotD / 2
                anchors.bottomMargin: col.dotD / 2
                radius: width / 2
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
                border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
                border.width: 1
            }

            readonly property real fillH: Math.max(track.radius * 2, track.height * col.value)

            // Fill
            Rectangle {
                id: fill
                anchors { left: track.left; right: track.right; bottom: track.bottom }
                radius: track.radius
                height: trackArea.fillH
                Behavior on height { NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic } }

                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: col.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18) : Qt.lighter(col.accent, 1.35) }
                    GradientStop { position: 1.0; color: col.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : col.accent }
                }
            }

            // Soft glow behind the indicator dot
            Rectangle {
                width: col.dotD * 2.4; height: width; radius: width / 2
                color: col.accent
                opacity: col.muted ? 0 : 0.22
                anchors.horizontalCenter: track.horizontalCenter
                y: track.y + track.height - trackArea.fillH - height / 2
                Behavior on y { NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic } }
                Behavior on opacity { NumberAnimation { duration: Anim.fast } }
            }

            // Indicator dot — sits exactly at the top of the fill
            Rectangle {
                id: dot
                width: col.dotD; height: width; radius: width / 2
                color: Theme.text
                border.width: 2
                border.color: col.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25) : col.accent
                anchors.horizontalCenter: track.horizontalCenter
                y: track.y + track.height - trackArea.fillH - height / 2
                Behavior on y { NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic } }

                scale: dragArea.pressed ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Anim.outBack } }
            }

            // Drag
            MouseArea {
                id: dragArea
                anchors.fill: track
                cursorShape: Qt.SizeVerCursor
                function calc(my) {
                    return Math.max(0.0, Math.min(1.0, 1.0 - my / track.height))
                }
                onPressed: col.volumeChanged(calc(mouseY))
                onPositionChanged: if (pressed) col.volumeChanged(calc(mouseY))
            }

            // Scroll
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(e) {
                    var step = 0.05
                    col.volumeChanged(Math.max(0.0, Math.min(1.0,
                        col.value + (e.angleDelta.y > 0 ? step : -step))))
                }
            }
        }

        // Icon / mute toggle
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: col.dotD + Math.round(20 * localScale); height: Math.round(30 * localScale)
            radius: height / 2
            color: col.muted
                   ? Qt.rgba(col.accent.r, col.accent.g, col.accent.b, 0.20)
                   : (btnHov.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05))
            border.color: btnHov.hovered ? Qt.rgba(col.accent.r, col.accent.g, col.accent.b, 0.45) : "transparent"
            border.width: 1
            Behavior on color { ColorAnimation { duration: Anim.fast } }
            Behavior on border.color { ColorAnimation { duration: Anim.fast } }

            Text {
                anchors.centerIn: parent
                text: col.icon
                font.pixelSize: Math.round(14 * localScale)
                color: col.muted ? col.accent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.65)
                Behavior on color { ColorAnimation { duration: Anim.fast } }
            }

            HoverHandler { id: btnHov; cursorShape: Qt.PointingHandCursor }
            MouseArea { anchors.fill: parent; onClicked: col.muteToggled() }
        }

        // Label
        Text {
            visible: col.label !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: col.label
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.30)
            font.pixelSize: Math.round(10 * localScale)
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1
            elide: Text.ElideRight
            width: col.dotD + Math.round(50 * localScale)
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
