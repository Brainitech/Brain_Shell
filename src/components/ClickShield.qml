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
import "../"

// A fullscreen invisible shield that catches clicks outside popups to close them
Item {
    id: root
    anchors.fill: parent
    
    // Only active when a surface is expanded
    property bool isActive: SurfaceState.activeSurface !== "none" || (ShellState.screenRecord && !ScreenRecService.recording) || Popups.miniPlayerOpen
    
    MouseArea {
        anchors.fill: parent
        enabled: root.isActive
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (Popups.miniPlayerOpen) {
                Popups.miniPlayerOpen = false
            } else if (ScreenRecService.optionsExpanded) {
                if (mouse.y > 100) {
                    ScreenRecService.optionsExpanded = false
                }
            } else {
                SurfaceState.close()
            }
        }
    }
}
