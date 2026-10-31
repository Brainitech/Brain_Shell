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
import Quickshell
import "../../../"

Rectangle {
    id: tileRoot

    property real localScale: 1.0
    property bool on: false
    property string icon: ""
    property string label: ""
    property string sublabel: ""

    signal toggled()
    signal rightToggled()

    radius: Math.round(10 * localScale)
    color: on
        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
        : hoverHandler.hovered
            ? Theme.cardHover
            : Theme.card
    border.color: on
        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30)
        : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.35)
    border.width: 1

    Behavior on color        { ColorAnimation { duration: Anim.color } }
    Behavior on border.color { ColorAnimation { duration: Anim.color } }

    Rectangle {
        id: statusDot
        anchors {
            top: parent.top
            right: parent.right
            margins: Math.round(8 * tileRoot.localScale)
        }
        width: Math.round(6 * tileRoot.localScale)
        height: width
        radius: width / 2
        color: tileRoot.on ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)

        Behavior on color { ColorAnimation { duration: Anim.color } }
    }

    Column {
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: Math.round(9 * tileRoot.localScale)
        }
        spacing: Math.round(2 * tileRoot.localScale)

        Text {
            id: iconText
            text: tileRoot.icon
            font.pixelSize: Math.round(17 * tileRoot.localScale)
            color: tileRoot.on ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.40)

            Behavior on color { ColorAnimation { duration: Anim.color } }
        }

        Text {
            id: labelText
            text: tileRoot.label
            font.pixelSize: Math.round(9 * tileRoot.localScale)
            font.weight: Font.Medium
            color: tileRoot.on ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)

            Behavior on color { ColorAnimation { duration: Anim.color } }
        }

        Text {
            id: sublabelText
            visible: tileRoot.sublabel !== ""
            text: tileRoot.sublabel
            font.pixelSize: Math.round(8 * tileRoot.localScale)
            font.family: "JetBrains Mono"
            color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.65)
            width: tileRoot.width - Math.round(18 * tileRoot.localScale)
            elide: Text.ElideRight
        }
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) tileRoot.rightToggled()
            else tileRoot.toggled()
        }
    }
}
