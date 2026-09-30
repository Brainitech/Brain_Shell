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
import QtQuick.Controls
import "../"

// Reusable scrollable page container for popup content.
// Clips content, shows a faint scrollbar when needed.
// Consistent vertical padding relative to popup height.
//
// Usage:
//   PopupPage {
//       anchors.fill: parent
//       // children go here — laid out top-to-bottom, scrollable if overflow
//   }

Item {
    id: root

    // All children go into the scroll content
    default property alias content: contentCol.data

    property real localScale: 1.0

    // Padding applied inside the scroll area
    property int padH: Math.round(6 * localScale)   // horizontal
    property int padV: Math.round(8 * localScale)   // vertical

    clip: true

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth:  width
        contentHeight: contentCol.implicitHeight + root.padV * 2
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        // Scroll with mouse wheel
        ScrollBar.vertical: ScrollBar {
            policy: Math.ceil(contentCol.implicitHeight + root.padV * 2) > Math.floor(flick.height) + 2
                        ? ScrollBar.AlwaysOn
                        : ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth:  Math.round(3 * localScale)
                implicitHeight: Math.round(40 * localScale)
                radius:         width / 2
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
            }
            background: Item {}
        }

        Column {
            id: contentCol
            anchors {
                top:        parent.top
                topMargin:  root.padV
                left:       parent.left
                leftMargin: root.padH
                // Reserve space for scrollbar when visible
                right:      parent.right
                rightMargin: root.padH + Math.round(6 * localScale)
            }
            spacing: Math.round(8 * localScale)
        }
    }
}
