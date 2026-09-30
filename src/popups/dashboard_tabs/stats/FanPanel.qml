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
import "../../"
import "../../../"
import "../../../components"

Item {
    id: root

    property real localScale: 1.0
    required property var service
    
    // Fallback UI when nbfc is not installed
    Text {
        anchors.centerIn: parent
        visible: !service.available
        text: "NBFC not installed"
        font.pixelSize: Math.round(14 * root.localScale)
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
    }

    Column {
        visible: service.available
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter
        spacing: Math.round(10 * localScale)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           "Fan Control"
            font.pixelSize: Math.round(14 * localScale)
            color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35)
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: parent.parent.width * 0.1

            ProfileButton {
                localScale: root.localScale
                icon:      "󱗰"
                label:     "Quiet"
                active:    service.mode === "quiet"
                onClicked: service.setMode("quiet")
            }
            ProfileButton {
                localScale: root.localScale
                icon:      "󰁪"
                label:     "Auto"
                active:    service.mode === "auto"
                onClicked: service.setMode("auto")
            }
            ProfileButton {
                localScale: root.localScale
                icon:      "󱓞"
                label:     "Max"
                active:    service.mode === "max"
                onClicked: service.setMode("max")
            }
        }
    }
}
