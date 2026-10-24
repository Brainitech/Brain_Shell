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

    readonly property int ringSize: Math.round(18 * localScale)

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Math.round(2 * root.localScale)
        radius: height / 2
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)

        Rectangle {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            height: Math.round(4 * root.localScale)
            width: parent.width * root.value
            radius: height / 2
            color: root.muted ? Theme.subtext : root.accent

            Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
            Behavior on width {
                enabled: !root.pressed
                NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic }
            }
        }
    }

    Rectangle {
        id: thumb
        anchors.verticalCenter: parent.verticalCenter
        width: root.ringSize
        height: root.ringSize
        radius: width / 2
        x: Math.max(0, Math.min(parent.width - width, root.value * (parent.width - width)))
        color: Theme.background
        border.width: Math.round(2 * root.localScale)
        border.color: root.muted ? Theme.subtext : (root.hovered || root.pressed ? root.accent : Theme.text)
        scale: root.pressed ? 1.25 : (root.hovered ? 1.12 : 1.0)

        Behavior on border.color { ColorAnimation { duration: Anim.fast } }
        Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Anim.outBack } }
        Behavior on x {
            enabled: !root.pressed
            NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.round(-3 * root.localScale)
            radius: width / 2
            color: "transparent"
            border.width: Math.round(1 * root.localScale)
            border.color: (root.pressed && !root.muted) ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5) : "transparent"
            Behavior on border.color { ColorAnimation { duration: Anim.fast } }
        }
    }
}
