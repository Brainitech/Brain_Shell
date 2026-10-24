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

    readonly property int spacing: Math.round(3 * localScale)
    readonly property int segH: Math.round(14 * localScale)
    readonly property int segmentCount: Math.max(12, Math.min(28, Math.floor(width / Math.max(1, Math.round(9 * localScale)))))

    Row {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: root.spacing

        Repeater {
            model: root.segmentCount
            Rectangle {
                readonly property real threshold: (index + 0.5) / root.segmentCount
                width: Math.max(2, (root.width - ((root.segmentCount - 1) * root.spacing)) / root.segmentCount)
                height: root.segH
                radius: Math.round(2 * root.localScale)

                color: {
                    if (root.muted) return Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.15)
                    if (root.value >= threshold) return root.accent
                    return Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.4)
                }

                Behavior on color { ColorAnimation { duration: Anim.superFast } }
            }
        }
    }
}
