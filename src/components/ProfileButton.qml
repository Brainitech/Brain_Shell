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

    property string label:   ""
    property string icon:    ""
    property bool   active:  false
    property real   localScale: 1.0
    // `enabled` is inherited from Item — no redeclaration needed

    signal clicked()

    implicitWidth:  row.implicitWidth + Math.round(24 * localScale)
    implicitHeight: Math.round(28 * localScale)

    opacity: root.enabled ? 1 : 0.35
    Behavior on opacity { NumberAnimation { duration: Anim.color} }

    Rectangle {
        anchors.fill: parent
        radius:       height / 2

        color: root.active
                   ? Theme.active
                   : (hov.hovered && root.enabled ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : "transparent")
        border.color: root.active
                          ? Theme.active
                          : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)
        border.width: 1

        Behavior on color        { ColorAnimation { duration: Anim.color} }
        Behavior on border.color { ColorAnimation { duration: Anim.color} }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(5 * localScale)

        Text {
            visible:        root.icon !== ""
            text:           root.icon
            font.pixelSize: Math.round(12 * localScale)
            color:          root.active ? Theme.background : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: Anim.color} }
        }

        Text {
            text:           root.label
            font.pixelSize: Math.round(11 * localScale)
            font.weight:    root.active ? Font.Medium : Font.Normal
            color:          root.active ? Theme.background : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: Anim.color} }
        }
    }

    HoverHandler { id: hov; cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    MouseArea {
        anchors.fill: parent
        enabled:      root.enabled
        onClicked:    root.clicked()
    }
}
