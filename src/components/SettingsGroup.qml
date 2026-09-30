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

Item {
    id: root
    property real localScale: 1.0
    property string title: ""
    property string description: ""
    default property alias content: innerCol.data

    width: parent ? parent.width : 400
    height: headerCol.height + card.height + Math.round(8 * localScale)

    Column {
        id: headerCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: Math.round(4 * localScale)

        Text {
            visible: root.title !== ""
            text: root.title
            color: Theme.text
            font.pixelSize: Math.round(14 * localScale)
            font.weight: Font.DemiBold
            leftPadding: Math.round(4 * localScale)
        }
        Text {
            visible: root.description !== ""
            text: root.description
            color: Theme.subtext
            font.pixelSize: Math.round(11 * localScale)
            leftPadding: Math.round(4 * localScale)
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    Rectangle {
        id: card
        anchors {
            top: headerCol.bottom
            topMargin: Math.round(8 * localScale)
            left: parent.left
            right: parent.right
        }
        height: innerCol.height + Math.round(16 * localScale)
        radius: Math.round(Theme.cornerRadius * localScale)
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
        border.color: Theme.border
        border.width: 1

        Column {
            id: innerCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Math.round(8 * localScale)
            }
            spacing: Math.round(4 * localScale)
        }
    }
}
