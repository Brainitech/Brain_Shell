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
import Quickshell.Wayland

// A phantom Wayland window used purely to reserve space (exclusive zone) for the compositor.
// This allows our fullscreen morphing canvas to remain unbroken while still pushing tiled windows away.
PanelWindow {
    property string edge: "top"
    property int reserveSpace: 40

    anchors {
        top: edge === "top"
        bottom: edge === "bottom"
        left: edge === "left"
        right: edge === "right"
    }
    
    // Size the phantom window to precisely the reserved space
    implicitWidth: (edge === "left" || edge === "right") ? reserveSpace : 100
    implicitHeight: (edge === "top" || edge === "bottom") ? reserveSpace : 100

    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Bottom // Kept out of the way
    WlrLayershell.namespace: "brain-shell-strut-" + edge
    WlrLayershell.exclusiveZone: reserveSpace
    
    // We don't want to accept ANY input on the strut window itself
    mask: Region {
        Region { x: 0; y: 0; width: 0; height: 0 }
    }
}
