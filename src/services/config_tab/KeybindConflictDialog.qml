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
import "../../"
import "../../components"

Item {
    id: root

    property real localScale: 1.0
    property string conflictLabel: ""
    property bool active: false

    signal dismissed()
    signal overrideAccepted()

    width: parent ? parent.width : 300
    height: Math.round(22 * localScale)
    opacity: (root.active && root.conflictLabel !== "") ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: Anim.color
        }
    }

    Row {
        anchors {
            left: parent.left
            leftMargin: Math.round(2 * root.localScale)
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: Math.round(4 * root.localScale)
        }
        spacing: Math.round(8 * root.localScale)

        Text {
            id: labelText
            anchors.verticalCenter: parent.verticalCenter
            text: "⚠  Conflicts with: " + root.conflictLabel
            font.pixelSize: Math.round(10 * root.localScale)
            color: Theme.error
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.width - (overrideBtn.visible ? Math.round(75 * root.localScale) : 0))
        }

        Rectangle {
            id: overrideBtn
            visible: root.active && root.conflictLabel !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(52 * root.localScale)
            height: Math.round(18 * root.localScale)
            radius: Math.round(4 * root.localScale)
            color: _ovrH.hovered
                ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.22)
                : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.10)
            border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.40)
            border.width: 1

            Behavior on color { ColorAnimation { duration: Anim.fast } }

            Text {
                anchors.centerIn: parent
                text: "Assign"
                font.pixelSize: Math.round(9 * root.localScale)
                font.weight: Font.Medium
                color: Theme.error
            }

            HoverHandler { id: _ovrH; cursorShape: Qt.PointingHandCursor }
            MouseArea {
                anchors.fill: parent
                onClicked: root.overrideAccepted()
            }
        }
    }
}
