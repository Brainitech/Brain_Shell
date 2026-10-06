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
    required property var cpuFreqService
    required property var envyService

    Column {
        anchors.centerIn: parent
        spacing:          Math.round(16 * localScale)

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(8 * localScale)

            // Label + lock icon hinting auto-cpufreq manages this
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(5 * localScale)

                Text {
                    text:           "󰌾"
                    font.pixelSize: Math.round(11 * localScale)
                    color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text:           "Power Profile"
                    font.pixelSize: Math.round(11 * localScale)
                    font.weight:    Font.Medium
                    color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(6 * localScale)

                ProfileButton {
                    localScale: root.localScale
                    label:     root.cpuFreqService.activeProfile === "performance" ? "Performance" : "Power Saver"
                    active:    true
                    enabled:   true
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width:  Math.round(200 * localScale)
            height: 1
            color:  Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(8 * localScale)
            visible: envyService.available

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "GPU Mode"
                font.pixelSize: Math.round(11 * localScale)
                font.weight:    Font.Medium
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.round(6 * localScale)

                ProfileButton {
                    localScale: root.localScale
                    label:     "Integrated"
                    active:    root.envyService.currentMode === "integrated"
                    enabled:   !root.envyService.busy
                    onClicked: root.envyService.switchMode("integrated")
                }
                ProfileButton {
                    localScale: root.localScale
                    label:     "Hybrid"
                    active:    root.envyService.currentMode === "hybrid"
                    enabled:   !root.envyService.busy
                    onClicked: root.envyService.switchMode("hybrid")
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "GPU mode switch requires a reboot"
                font.pixelSize: Math.round(10 * localScale)
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
            }
        }

        // Fallback for missing envycontrol
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(8 * localScale)
            visible: !envyService.available

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "GPU Mode"
                font.pixelSize: Math.round(11 * localScale)
                font.weight:    Font.Medium
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "EnvyControl not installed"
                font.pixelSize: Math.round(12 * localScale)
                color:          Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
            }
        }
    }
}
