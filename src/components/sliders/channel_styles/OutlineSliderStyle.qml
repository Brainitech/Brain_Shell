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

    readonly property int trackHeight: Math.round(160 * localScale)
    readonly property int barW: Math.round(36 * localScale)
    readonly property int pad: Math.round(6 * localScale)

    signal volumeChanged(real value)
    signal muteToggled()

    implicitWidth: inner.implicitWidth
    implicitHeight: inner.implicitHeight
    width: implicitWidth
    height: implicitHeight

    readonly property string pctText: active ? Math.round(value * 100) + "%" : "--%"

    Column {
        id: inner
        anchors.centerIn: parent
        spacing: Math.round(12 * localScale)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: col.pctText
            color: col.muted ? Theme.subtext : Theme.text
            font.pixelSize: Math.round(14 * localScale)
            font.bold: true
            Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: col.barW
            height: col.trackHeight

            // Hollow Track Outline
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: (mouse.pressed || trackHov.hovered) ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.03) : "transparent"
                border.width: Math.round(2 * col.localScale)
                border.color: col.muted ? Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.4) : Theme.border
                Behavior on color { ColorAnimation { duration: Anim.fast } }
                Behavior on border.color { ColorAnimation { duration: Anim.mediumFast } }
            }

            // Inner Fill Container
            Item {
                anchors.fill: parent
                anchors.margins: col.pad

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: Math.max(0, parent.height * col.value)
                    radius: width / 2
                    color: col.muted ? Theme.subtext : col.accent
                    Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
                    Behavior on height { NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic } }
                }
            }

            HoverHandler { id: trackHov }
            MouseArea {
                id: mouse
                anchors.fill: parent
                cursorShape: Qt.SizeVerCursor

                function calc(my) {
                    var travel = col.trackHeight - (col.pad * 2)
                    var innerY = my - col.pad
                    return Math.max(0.0, Math.min(1.0, 1.0 - (innerY / travel)))
                }

                onPressed: col.volumeChanged(calc(mouseY))
                onPositionChanged: if (pressed) col.volumeChanged(calc(mouseY))
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(event) {
                    var step = 0.05
                    var delta = event.angleDelta.y > 0 ? step : -step
                    col.volumeChanged(Math.max(0.0, Math.min(1.0, col.value + delta)))
                }
            }
        }

        // Action Button
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: col.barW + Math.round(12 * localScale)
            height: Math.round(36 * localScale)
            radius: height / 2
            color: col.muted ? Qt.rgba(col.accent.r, col.accent.g, col.accent.b, 0.15) : "transparent"
            border.color: col.muted ? col.accent : Theme.border
            border.width: Math.round(2 * localScale)
            Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
            Behavior on border.color { ColorAnimation { duration: Anim.mediumFast } }

            Text {
                anchors.centerIn: parent
                text: col.icon
                font.pixelSize: Math.round(16 * localScale)
                color: col.muted ? col.accent : Theme.icon
                Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
            }

            Rectangle {
                anchors.fill: parent; radius: parent.radius
                color: muteHov.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05) : "transparent"
                Behavior on color { ColorAnimation { duration: Anim.fast } }
            }
            HoverHandler { id: muteHov; cursorShape: Qt.PointingHandCursor }
            MouseArea { anchors.fill: parent; onClicked: col.muteToggled() }
        }

        Text {
            visible: col.label !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: col.label
            color: Theme.subtext
            font.pixelSize: Math.round(10 * localScale)
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 2
            elide: Text.ElideRight
            width: col.barW + Math.round(40 * localScale)
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
