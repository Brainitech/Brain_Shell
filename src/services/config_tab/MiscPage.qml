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
import "../../components"
import "../../"

Item {
    id: root
    property real localScale: 1.0

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.height + Math.round(40 * localScale)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            width: parent.width
            spacing: Math.round(32 * localScale)
            anchors.top: parent.top
            anchors.topMargin: Math.round(10 * localScale)

            SettingsGroup {
                localScale: root.localScale
                title: "Miscellaneous"
                description: "Advanced system integrations and external tooling."

                Item {
                    width: parent.width
                    height: 60
                    Text {
                        anchors.centerIn: parent
                        text: "More Options Coming Soon..."
                        font.pixelSize: Math.round(13 * root.localScale)
                        font.italic: true
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                    }
                }
            }
        }
    }
}
