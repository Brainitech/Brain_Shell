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
import "../"

// A single horizontal label / value pair.
// Label is dimmed, value is bright by default.
// valueColor can be overridden for highlights (e.g. up/down arrows).

Item {
    id: root

    property string label:      ""
    property string value:      ""
    property color  valueColor: Theme.text
    property real   localScale: 1.0

    implicitHeight: Math.round(20 * localScale)

    Text {
        anchors.left:           parent.left
        anchors.verticalCenter: parent.verticalCenter
        text:           root.label
        font.pixelSize: Math.round(11 * localScale)
        color:          Theme.subtext
    }

    Text {
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter
        text:           root.value
        font.pixelSize: Math.round(11 * localScale)
        color:          root.valueColor
    }
}
