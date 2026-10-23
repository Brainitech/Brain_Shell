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
    readonly property int ringSize: Math.round(40 * localScale)
    readonly property int dotCount: 24

    signal volumeChanged(real value)
    signal muteToggled()

    implicitWidth: inner.implicitWidth
    implicitHeight: inner.implicitHeight
    width: implicitWidth
    height: implicitHeight

    readonly property string pctText: active ? Math.round(value * 100) : "--"

    Column {
        id: inner
        anchors.centerIn: parent
        spacing: Math.round(16 * localScale)

        Item { width: 1; height: Math.round(10 * localScale) }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: col.ringSize
            height: col.trackHeight

            // Dotted Track
            Repeater {
                model: col.dotCount
                Rectangle {
                    property real myVal: 1.0 - (index / (col.dotCount - 1))
                    width: Math.round(4 * col.localScale)
                    height: width
                    radius: width / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: index * ((parent.height - height) / (col.dotCount - 1))

                    color: {
                        if (col.muted) return Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.4)
                        if (col.value >= myVal - 0.01) return col.accent
                        return Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                    }
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                }
            }

            // Floating Ring Thumb with integrated text
            Rectangle {
                id: thumb
                width: col.ringSize
                height: col.ringSize
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter

                property real dotH: Math.round(4 * col.localScale)
                property real topY: (dotH / 2) - (height / 2)
                property real bottomY: parent.height - (dotH / 2) - (height / 2)

                y: bottomY - (col.value * (bottomY - topY))

                color: Theme.background
                border.width: Math.round(2 * col.localScale)
                border.color: col.muted ? Theme.subtext : (ringHov.hovered || mouse.pressed ? col.accent : Theme.text)
                Behavior on border.color { ColorAnimation { duration: Anim.mediumFast } }

                Text {
                    anchors.centerIn: parent
                    text: col.pctText
                    color: col.muted ? Theme.subtext : Theme.text
                    font.pixelSize: Math.round(12 * col.localScale)
                    font.bold: true
                    font.family: "monospace"
                    Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
                }

                // Hover glow ring
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Math.round(-4 * col.localScale)
                    radius: width / 2
                    color: "transparent"
                    border.width: Math.round(1 * col.localScale)
                    border.color: (mouse.pressed && !col.muted) ? Qt.rgba(col.accent.r, col.accent.g, col.accent.b, 0.4) : "transparent"
                    Behavior on border.color { ColorAnimation { duration: Anim.fast } }
                }

                HoverHandler { id: ringHov; cursorShape: Qt.PointingHandCursor }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                anchors.topMargin: -Math.round(16 * col.localScale)
                anchors.bottomMargin: -Math.round(16 * col.localScale)
                cursorShape: Qt.SizeVerCursor

                function calc(my) {
                    var adjustedY = my - Math.round(16 * col.localScale)
                    var topY = thumb.topY
                    var bottomY = thumb.bottomY
                    var travel = bottomY - topY
                    var targetThumbY = adjustedY - (thumb.height / 2)
                    return Math.max(0.0, Math.min(1.0, 1.0 - ((targetThumbY - topY) / travel)))
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

        Item { width: 1; height: Math.round(10 * localScale) }

        // Action Button
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: col.ringSize + Math.round(12 * localScale)
            height: Math.round(36 * localScale)
            radius: height / 2
            color: col.muted ? Qt.rgba(col.accent.r, col.accent.g, col.accent.b, 0.15) : "transparent"
            border.color: col.muted ? col.accent : Theme.border
            border.width: Math.round(1.5 * localScale)
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
            width: col.ringSize + Math.round(20 * localScale)
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
