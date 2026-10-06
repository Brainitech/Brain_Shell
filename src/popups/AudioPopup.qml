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
import "../services"
import "../"

Item {
    id: root

    property real localScale: 1.0

    readonly property int popupHeight: Math.round(340 * root.localScale)
    readonly property int maxWidth: Math.round(300 * root.localScale)

    readonly property var pageWidths: ({
        "output": Math.round(200 * root.localScale),
        "input":  Math.round(200 * root.localScale),
        "mixer":  Math.round(300 * root.localScale)
    })
    
    // Animate target width slightly for tab changes
    property real targetWidth: (pageWidths[Popups.audioPage] ?? maxWidth)

    readonly property int popupWidth: targetWidth

    onOpacityChanged: if (opacity === 1) forceActiveFocus()
    Keys.onEscapePressed: SurfaceState.close()

    MouseArea {
        anchors.fill: parent
        onClicked: Popups.audioPinned = true
    }

    Item {
        id: slide
        anchors.fill: parent
        clip: true

        onOpacityChanged: {
            if (opacity === 1 && !(SurfaceState.activeContent === "audio")) {
                let opt = PrefsService.defaultAudioTab
                if (opt === "Input") Popups.audioPage = "input"
                else if (opt === "Mixers") Popups.audioPage = "mixer"
                else Popups.audioPage = "output"
            }
        }

        AudioControl {
            id: audioControl
            localScale: root.localScale
            fullyOpen: (SurfaceState.activeContent === "audio") && root.opacity === 1

            width: root.targetWidth - Math.round(16 * root.localScale)
            height: root.popupHeight - Math.round(16 * root.localScale)
            
            anchors.centerIn: parent
        }
    }
}
