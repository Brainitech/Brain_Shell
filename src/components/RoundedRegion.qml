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

Region {
    id: root

    property int rectX: 0
    property int rectY: 0
    property int rectWidth: 0
    property int rectHeight: 0
    property int cornerRadius: 0

    property bool roundTopLeft: true
    property bool roundTopRight: true
    property bool roundBottomLeft: true
    property bool roundBottomRight: true

    readonly property int r: Math.max(0, Math.min(cornerRadius, Math.floor(rectWidth / 2), Math.floor(rectHeight / 2)))

    // Central horizontal and vertical strips
    Region {
        x: root.rectX + (root.roundTopLeft || root.roundBottomLeft ? root.r : 0)
        y: root.rectY
        width: Math.max(0, root.rectWidth - (root.roundTopLeft || root.roundBottomLeft ? root.r : 0) - (root.roundTopRight || root.roundBottomRight ? root.r : 0))
        height: Math.max(0, root.rectHeight)
    }
    Region {
        x: root.rectX
        y: root.rectY + (root.roundTopLeft || root.roundTopRight ? root.r : 0)
        width: Math.max(0, root.rectWidth)
        height: Math.max(0, root.rectHeight - (root.roundTopLeft || root.roundTopRight ? root.r : 0) - (root.roundBottomLeft || root.roundBottomRight ? root.r : 0))
    }

    // Top-Left Corner
    Region {
        x: root.rectX
        y: root.rectY
        width: !root.roundTopLeft && root.r > 0 ? root.r : 0
        height: !root.roundTopLeft && root.r > 0 ? root.r : 0
    }
    Region {
        x: root.rectX
        y: root.rectY
        width: root.roundTopLeft && root.r > 0 ? 2 * root.r : 0
        height: root.roundTopLeft && root.r > 0 ? 2 * root.r : 0
        shape: RegionShape.Ellipse
    }

    // Top-Right Corner
    Region {
        x: root.rectX + root.rectWidth - root.r
        y: root.rectY
        width: !root.roundTopRight && root.r > 0 ? root.r : 0
        height: !root.roundTopRight && root.r > 0 ? root.r : 0
    }
    Region {
        x: root.rectX + root.rectWidth - 2 * root.r
        y: root.rectY
        width: root.roundTopRight && root.r > 0 ? 2 * root.r : 0
        height: root.roundTopRight && root.r > 0 ? 2 * root.r : 0
        shape: RegionShape.Ellipse
    }

    // Bottom-Left Corner
    Region {
        x: root.rectX
        y: root.rectY + root.rectHeight - root.r
        width: !root.roundBottomLeft && root.r > 0 ? root.r : 0
        height: !root.roundBottomLeft && root.r > 0 ? root.r : 0
    }
    Region {
        x: root.rectX
        y: root.rectY + root.rectHeight - 2 * root.r
        width: root.roundBottomLeft && root.r > 0 ? 2 * root.r : 0
        height: root.roundBottomLeft && root.r > 0 ? 2 * root.r : 0
        shape: RegionShape.Ellipse
    }

    // Bottom-Right Corner
    Region {
        x: root.rectX + root.rectWidth - root.r
        y: root.rectY + root.rectHeight - root.r
        width: !root.roundBottomRight && root.r > 0 ? root.r : 0
        height: !root.roundBottomRight && root.r > 0 ? root.r : 0
    }
    Region {
        x: root.rectX + root.rectWidth - 2 * root.r
        y: root.rectY + root.rectHeight - 2 * root.r
        width: root.roundBottomRight && root.r > 0 ? 2 * root.r : 0
        height: root.roundBottomRight && root.r > 0 ? 2 * root.r : 0
        shape: RegionShape.Ellipse
    }
}
