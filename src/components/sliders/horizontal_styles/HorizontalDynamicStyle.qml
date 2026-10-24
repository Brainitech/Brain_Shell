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

    readonly property int minH: Math.round(5 * localScale)
    readonly property int maxH: Math.round(14 * localScale)

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: (root.hovered || root.pressed) ? root.maxH : root.minH
        radius: height / 2
        color: root.muted ? Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.4) : Theme.border

        Behavior on height { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic } }
        Behavior on color { ColorAnimation { duration: Anim.fast } }

        Rectangle {
            id: fill
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: Math.max(parent.radius * 2, parent.width * root.value)
            radius: parent.radius
            color: root.muted ? Theme.subtext : root.accent

            Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
            Behavior on width {
                enabled: !root.pressed
                NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic }
            }
        }
    }
}
