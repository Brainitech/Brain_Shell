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

    readonly property int dotD: Math.round(14 * localScale)
    readonly property int trackH: Math.round(6 * localScale)

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackH
        radius: height / 2
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
        border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
        border.width: 1

        Rectangle {
            id: fill
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: Math.max(parent.radius * 2, parent.width * root.value)
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : root.accent }
                GradientStop { position: 1.0; color: root.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.20) : Qt.lighter(root.accent, 1.35) }
            }

            Behavior on width {
                enabled: !root.pressed
                NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic }
            }
        }
    }

    Rectangle {
        width: root.dotD * 2.2
        height: width
        radius: width / 2
        color: root.accent
        opacity: root.muted ? 0 : (root.pressed ? 0.35 : (root.hovered ? 0.25 : 0.18))
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, root.value * (parent.width - root.dotD) - (width - root.dotD) / 2))

        Behavior on opacity { NumberAnimation { duration: Anim.fast } }
        Behavior on x {
            enabled: !root.pressed
            NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic }
        }
    }

    Rectangle {
        id: dot
        width: root.dotD
        height: root.dotD
        radius: width / 2
        color: Theme.text
        border.width: 2
        border.color: root.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25) : root.accent
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, root.value * (parent.width - width)))
        scale: root.pressed ? 1.25 : (root.hovered ? 1.12 : 1.0)

        Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Anim.outBack } }
        Behavior on x {
            enabled: !root.pressed
            NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic }
        }
    }
}
