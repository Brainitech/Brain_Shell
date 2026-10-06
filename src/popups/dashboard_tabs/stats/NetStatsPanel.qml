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

    Column {
        anchors.centerIn: parent
        width:            parent.width - Math.round(16 * localScale)
        spacing:          Math.round(10 * localScale)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           "Network"
            font.pixelSize: Math.round(11 * localScale)
            font.weight:    Font.Medium
            color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
        }

        Column {
            width:   parent.width
            spacing: Math.round(6 * localScale)

            StatRow {
                localScale: root.localScale
                width:      parent.width
                label:      "Interface"
                value:      root.service.iface
            }

            StatRow {
                localScale: root.localScale
                width:      parent.width
                label:      "↑ Upload"
                value:      root.service.upSpeed
                valueColor: Theme.netUpload
            }

            StatRow {
                localScale: root.localScale
                width:      parent.width
                label:      "↓ Download"
                value:      root.service.downSpeed
                valueColor: Theme.netDownload
            }
        }
    }
}
