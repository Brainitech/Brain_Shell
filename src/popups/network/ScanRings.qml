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

Item {
    id: ringsRoot

    property real localScale: 1.0
    property bool running: false
    property string centerGlyph: "󰤨"
    property int glyphSize: Math.round(18 * localScale)

    Repeater {
        model: 4
        delegate: Rectangle {
            required property int index
            anchors.centerIn: parent
            width: ringsRoot.width
            height: ringsRoot.width
            radius: ringsRoot.width / 2
            color: "transparent"
            border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.80)
            border.width: Math.max(1, Math.round(1.5 * localScale))
            opacity: 0
            scale: 0.08

            SequentialAnimation {
                running: ringsRoot.running
                loops: Animation.Infinite
                PauseAnimation { duration: index * 650 }
                ParallelAnimation {
                    NumberAnimation {
                        property: "scale"
                        from: 0.08
                        to: 1.0
                        duration: Anim.megaSlow
                        easing.type: Anim.outCubic
                        easing.overshoot: Anim.globalOvershoot
                        easing.amplitude: Anim.globalAmplitude
                        easing.period: Anim.globalPeriod
                    }
                    NumberAnimation {
                        property: "opacity"
                        from: 0.80
                        to: 0.0
                        duration: Anim.megaSlow
                        easing.type: Anim.outQuad
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: ringsRoot.centerGlyph
        font.pixelSize: ringsRoot.glyphSize
        color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)

        SequentialAnimation on opacity {
            running: ringsRoot.running
            loops: Animation.Infinite
            NumberAnimation { to: 0.20; duration: Anim.extraSlow; easing.type: Anim.inOutSine }
            NumberAnimation { to: 0.80; duration: Anim.extraSlow; easing.type: Anim.inOutSine }
        }
    }
}
