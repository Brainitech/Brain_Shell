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

    readonly property int trackHeight: Math.round(180 * localScale)
    readonly property int barW: Math.round(36 * localScale)

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
            font.pixelSize: Math.round(13 * localScale)
            font.bold: true
            Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: col.barW
            height: col.trackHeight

            Column {
                anchors.fill: parent
                spacing: Math.round(3 * col.localScale)
                Repeater {
                    model: 24
                    Rectangle {
                        property real threshold: 1.0 - ((index + 0.5) / 24.0)
                        width: parent.width
                        height: (col.trackHeight - (23 * Math.round(3 * col.localScale))) / 24
                        radius: Math.round(2 * col.localScale)
                        color: {
                            if (col.muted) return Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.15)
                            if (col.value >= threshold) return col.accent
                            return Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.4)
                        }
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeVerCursor
                onPressed: col.volumeChanged(Math.max(0.0, Math.min(1.0, 1.0 - mouseY / col.trackHeight)))
                onPositionChanged: if (pressed) col.volumeChanged(Math.max(0.0, Math.min(1.0, 1.0 - mouseY / col.trackHeight)))
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

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: col.barW + Math.round(16 * localScale)
            height: Math.round(32 * localScale)
            radius: height / 2
            color: col.muted ? Qt.rgba(col.accent.r, col.accent.g, col.accent.b, 0.15) : "transparent"
            border.color: col.muted ? col.accent : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.6)
            border.width: Math.round(1.5 * localScale)
            Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
            Behavior on border.color { ColorAnimation { duration: Anim.mediumFast } }

            Row {
                anchors.centerIn: parent
                spacing: Math.round(6 * localScale)
                Text {
                    text: col.icon
                    font.pixelSize: Math.round(14 * localScale)
                    color: col.muted ? col.accent : Theme.icon
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
                }
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
            width: col.barW + Math.round(60 * localScale)
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
