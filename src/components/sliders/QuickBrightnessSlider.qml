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

        HorizontalSliderTrack {
            id: btw
            width: Math.max(0, parent.width - Math.round(13 * sliderRoot.localScale) * 2 - sliderRow.spacing * 2)
            height: Math.round(30 * sliderRoot.localScale)
            anchors.verticalCenter: parent.verticalCenter
            localScale: sliderRoot.localScale
            value: sliderRoot.value
            accent: Theme.active
            onValueMoved: function(v) {
                BrightnessService.setBrightness(Math.round(v * 100))
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
