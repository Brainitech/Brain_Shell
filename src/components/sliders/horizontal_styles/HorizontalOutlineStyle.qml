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

    readonly property int pad: Math.round(3 * localScale)
    readonly property int frameH: Math.round(14 * localScale)

    Rectangle {
        id: frame
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.frameH
        radius: height / 2
        color: (root.pressed || root.hovered) ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04) : "transparent"
        border.width: Math.round(2 * root.localScale)
        border.color: root.muted ? Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.4) : Theme.border

        Behavior on color { ColorAnimation { duration: Anim.fast } }
        Behavior on border.color { ColorAnimation { duration: Anim.mediumFast } }

        Item {
            anchors.fill: parent
            anchors.margins: root.pad

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: Math.max(0, parent.width * root.value)
                radius: height / 2
                color: root.muted ? Theme.subtext : root.accent

                Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
                Behavior on width {
                    enabled: !root.pressed
                    NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic }
                }
            }
        }
    }
}
