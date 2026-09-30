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

Rectangle {
    id: root
    property real localScale: 1.0
    width: Math.round(24 * localScale)
    height: Math.round(24 * localScale)
    radius: Math.round(4 * localScale)
    
    color: hover.hovered ? Theme.active : "transparent"
    
    property string text: "" 
    property color textColor: Theme.text
    property int fontSize: Math.round(14 * localScale)
    signal clicked()

    Text {
        anchors.centerIn: parent
        text: root.text
        
        color: hover.hovered ? Theme.background : root.textColor
        
        font.pixelSize: root.fontSize
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
