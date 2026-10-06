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

pragma Singleton
import QtQuick
import "../"

QtObject {
    id: root
    
    // Physical state of the morphing surfaces
    property string activeSurface: "none" // "none", "top", "left", "right", "bottom"
    property string activeContent: "none" // "dashboard", "archMenu", "audio", "network", "notifications"

    // Global toggle logic
    function toggle(surface, content) {
        if (activeSurface === surface && activeContent === content) {
            close()
        } else {
            open(surface, content)
        }
    }

    function open(surface, content) {
        if (ShellState.screenRecord && !ScreenRecService.recording) return
        root.activeSurface = surface
        root.activeContent = content
    }

    property real lastCloseTime: 0

    function close() {
        lastCloseTime = Date.now()
        root.activeSurface = "none"
        root.activeContent = "none"
    }

    // Helper booleans for property binding
    readonly property bool isTopExpanded: activeSurface === "top"
    readonly property bool isRightExpanded: activeSurface === "right"
    // Additional morphing borders
    readonly property bool isLeftCenterExpanded: activeSurface === "leftCenter"
    readonly property bool isRightCenterExpanded: activeSurface === "rightCenter"
    readonly property bool isBottomCenterExpanded: activeSurface === "bottomCenter"
    readonly property bool isBottomRightExpanded: activeSurface === "bottomRight"
}
