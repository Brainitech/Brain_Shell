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
import "../../"
import "../../services"

Item {
    id: sliderRoot

    property real localScale: 1.0
    readonly property real value: BrightnessService.brightness / 100

    implicitWidth: parent ? parent.width : 300
    implicitHeight: Math.round(52 * sliderRoot.localScale)
    width: parent ? parent.width : implicitWidth
    height: implicitHeight

    Text {
        id: brightLbl
        anchors {
            left: parent.left
            top: parent.top
        }
        text: "BRIGHTNESS"
        font.pixelSize: Math.round(9 * sliderRoot.localScale)
        font.weight: Font.Bold
        color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)
    }

    Text {
        id: brightValText
        anchors {
            right: parent.right
            top: parent.top
        }
        text: Math.round(sliderRoot.value * 100) + "%"
        font.pixelSize: Math.round(9 * sliderRoot.localScale)
        font.family: "JetBrains Mono"
        font.weight: Font.Bold
        color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.7)
    }

    Row {
        id: sliderRow
        anchors {
            left: parent.left
            right: parent.right
            top: brightLbl.bottom
            topMargin: Math.round(8 * sliderRoot.localScale)
        }
        spacing: Math.round(8 * sliderRoot.localScale)

        Text {
            id: minIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "󰃞"
            font.pixelSize: Math.round(13 * sliderRoot.localScale)
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35)
        }

        Item {
            id: btw
            width: Math.max(0, parent.width - Math.round(13 * sliderRoot.localScale) * 2 - sliderRow.spacing * 2)
            height: Math.round(30 * sliderRoot.localScale)
            anchors.verticalCenter: parent.verticalCenter
            readonly property int thumbD: Math.round(14 * sliderRoot.localScale)

            Rectangle {
                id: btrack
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Math.round(5 * sliderRoot.localScale)
                radius: height / 2
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)

                Rectangle {
                    id: bfill
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: Math.max(parent.radius * 2, parent.width * sliderRoot.value)
                    radius: parent.radius
                    color: Theme.active
                    Behavior on width {
                        NumberAnimation {
                            duration: Anim.superFast
                            easing.type: Anim.outCubic
                            easing.overshoot: Anim.globalOvershoot
                            easing.amplitude: Anim.globalAmplitude
                            easing.period: Anim.globalPeriod
                        }
                    }
                }

                MouseArea {
                    id: bMouse
                    anchors.fill: parent
                    anchors.topMargin: -Math.round(8 * sliderRoot.localScale)
                    anchors.bottomMargin: -Math.round(8 * sliderRoot.localScale)
                    cursorShape: Qt.PointingHandCursor

                    function _calc(mx) {
                        return Math.max(0.0, Math.min(1.0, (mx - btw.thumbD / 2) / (btrack.width - btw.thumbD)))
                    }

                    onPressed: BrightnessService.setBrightness(Math.round(_calc(mouseX) * 100))
                    onPositionChanged: if (pressed) BrightnessService.setBrightness(Math.round(_calc(mouseX) * 100))
                }
            }

            WheelHandler {
                id: bWheel
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(e) {
                    var step = e.angleDelta.y > 0 ? 0.05 : -0.05
                    BrightnessService.setBrightness(Math.round((sliderRoot.value + step) * 100))
                }
            }

            Rectangle {
                id: bthumb
                width: btw.thumbD
                height: btw.thumbD
                radius: btw.thumbD / 2
                color: Theme.text
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(btw.width - width, sliderRoot.value * (btw.width - width)))
                Behavior on x {
                    NumberAnimation {
                        duration: Anim.superFast
                        easing.type: Anim.outCubic
                        easing.overshoot: Anim.globalOvershoot
                        easing.amplitude: Anim.globalAmplitude
                        easing.period: Anim.globalPeriod
                    }
                }
            }
        }

        Text {
            id: maxIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "󰃠"
            font.pixelSize: Math.round(13 * sliderRoot.localScale)
            color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.75)
        }
    }
}
