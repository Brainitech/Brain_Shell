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
    id: root
    property real localScale: 1.0
    property real value: 0.0
    property color accent: Theme.active
    property bool active: true
    property bool muted: false
    property bool hovered: false
    property bool pressed: false

    readonly property int thumbD: Math.round(14 * localScale)
    readonly property int trackH: Math.round(6 * localScale)

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackH
        radius: height / 2
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)

        Rectangle {
            id: fill
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: Math.max(parent.radius * 2, parent.width * root.value)
            radius: parent.radius
            color: root.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18) : root.accent

            Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
            Behavior on width {
                enabled: !root.pressed
                NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic }
            }
        }
    }

    Rectangle {
        id: thumb
        width: root.thumbD
        height: root.thumbD
        radius: width / 2
        color: Theme.text
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.2)
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, root.value * (parent.width - width)))
        scale: root.pressed ? 1.2 : (root.hovered ? 1.1 : 1.0)

        Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Anim.outBack } }
        Behavior on x {
            enabled: !root.pressed
            NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic }
        }
    }
}
