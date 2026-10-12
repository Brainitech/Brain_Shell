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
import "../../"

// ─── LayoutDisplayer ────────────────────────────────────────────────────────
// Small icon button beside the Workspaces module.
// Shows the active tiling layout for the focused workspace.
//
// Layout → symbol map:
//   dwindle  → ><    (nf-md-view_quilt)
//   master   → M     (nf-md-view_split_vertical)
//   monocle  → |N|   (nf-md-fullscreen)
//   scroller → <N>   (nf-md-scroll_horizontal)
// ────────────────────────────────────────────────────────────────────────────

Item {
    id: root

    property real localScale: 1.0

    implicitWidth:  Math.round(26 * localScale)
    implicitHeight: Math.round(26 * localScale)

    // ── State ────────────────────────────────────────────────────────────────
    readonly property string currentLayout: WM.currentLayout
    readonly property string numWindows: WM.numWindows

    // ── Symbol map ───────────────────────────────────────────────────────────
    function layoutSymbol(name) {
        switch (name.toLowerCase()) {
            case "dwindle":   return "><"
            case "master":    return "M"
            case "monocle":   return "|" + root.numWindows + "|"
            case "scrolling": return "<" + root.numWindows + ">"
            default:          return "Unknown"
        }
    }

    // ── Visual ───────────────────────────────────────────────────────────────
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Math.round(6 * localScale)
        color: mouseArea.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : "transparent"

        Behavior on color {
            ColorAnimation { duration: Anim.color }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    WM.cycleLayout(1)
                } else if (mouse.button === Qt.RightButton) {
                    WM.cycleLayout(-1)
                }
            }
        }

        Text {
            id: icon
            anchors.centerIn: parent
            text: root.currentLayout !== "" ? layoutSymbol(root.currentLayout) : "…"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Math.round(14 * localScale)
            color: Theme.text

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation {
                        target: icon; property: "scale"
                        to: 0.6; duration: Anim.superFast
                        easing.type: Anim.inQuad
                    }
                    NumberAnimation {
                        target: icon; property: "scale"
                        to: 1.0; duration: Anim.color
                        easing.type: Anim.outBack; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod
                    }
                }
            }
        }
    }
}
