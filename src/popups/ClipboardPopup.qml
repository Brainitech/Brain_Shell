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
import "../components"
import "../"

Item {
    id: root

    property real localScale: 1.0

    readonly property int popupWidth:  Math.round(420 * root.localScale)
    readonly property int popupHeight: Math.round(560 * root.localScale)
        



    

    // ── Content ────────────────────────────────────────────
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.popupWidth
        height: root.popupHeight

        Item {
            anchors.fill: parent

            opacity: (SurfaceState.activeContent === "clipboard") ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
            onOpacityChanged: {
                if (opacity === 1) historyTab.grabFocus()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Popups.clipboardPinned = true
            }

            HistoryTab {
                id: historyTab
                anchors.fill: parent
                anchors.margins: Math.round(8 * root.localScale)
                localScale: root.localScale
            }
        }
    }
}