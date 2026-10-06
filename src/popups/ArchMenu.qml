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
import "../services"
import "../components"
import "../"

Item {
    id: root

    property real localScale: 1.0

        
    readonly property var pageHeights: ({
        "power":       Math.round(270 * root.localScale),
        "performance": Math.round(190 * root.localScale),
        "stats":       Math.round(250 * root.localScale)
    })
    readonly property var pageWidths: ({
        "power":       Math.round(220 * root.localScale),
        "performance": Math.round(260 * root.localScale),
        "stats":       Math.round(390 * root.localScale)
    })

    readonly property int contentWidth:  pageWidths[page]  ?? Math.round(220 * root.localScale)
    readonly property int contentHeight: pageHeights[page] ?? Math.round(220 * root.localScale)
    readonly property int popupWidth: contentWidth
    readonly property int popupHeight: contentHeight

    property string page: "power"

    onOpacityChanged: {
        if (opacity === 1) {
            if (page === "power") powerMenuRef.forceActiveFocus()
            else forceActiveFocus()
        }
    }
    Keys.onEscapePressed: SurfaceState.close()
    MouseArea {
        anchors.fill: parent
        onClicked: Popups.archMenuPinned = true
    }

    Item {
        id: slide
        anchors.fill: parent
        clip: true

        Item {
            anchors {
                fill:         parent
                leftMargin:   Math.round(8 * root.localScale)
                rightMargin:  Math.round(8 * root.localScale)
                topMargin:    Math.round(8 * root.localScale)
                bottomMargin: Math.round(8 * root.localScale)
            }
            
            //── Page content ──────────────────────────────────────────
            Item {
                anchors.centerIn: parent
                width:  root.contentWidth - Math.round(16 * root.localScale)
                height: root.contentHeight - Math.round(16 * root.localScale)
                clip:   true

                PopupPage {
                    localScale: root.localScale
                    anchors.fill: parent
                    visible: root.page === "power"

                    PowerMenu {
                        id: powerMenuRef
                        localScale: root.localScale
                        width: parent.width
                    }
                }
            }
        }
    }
}
