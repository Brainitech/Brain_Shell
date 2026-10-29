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
import "../"
import "../theme"
import "../services"
import "../popups/"
import "../components"
import "../modules/Right/"
import "../modules/Center/"
import "../modules/Left/"

// A morphing Wayland window layer for the unified screen frame
PanelWindow {
    id: root
    // --- CLICK SHIELD ---
    ClickShield { id: clickShield }
    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    readonly property alias surfaceShape: surfaceShape
    readonly property alias focusTriggers: focusTriggers
    readonly property alias sideBottomSurfaces: sideBottomSurfaces

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    exclusionMode: ExclusionMode.Ignore
    
    color: "transparent"

    // --- INPUT MANAGER ---
    SurfaceInputManager {
        id: inputManager
        anchors.fill: parent
        localScale: root.localScale
        surfaceShape: surfaceShape
        clickShield: clickShield
        screenRecord: ShellState.screenRecord
        screenRecording: ScreenRecService.recording
        optionsExpanded: ScreenRecService.optionsExpanded
        isTopHovered: leftNotchHover.hovered || centerNotchHover.hovered || rightNotchHover.hovered || (dashboardContainer && dashboardHover.hovered)
        isRightHovered: rightNotchHover.hovered || (rightPopupContainer && rightPopupHover.hovered)
        isLeftCenterHovered: sideBottomSurfaces.isLeftCenterHovered
        isRightCenterHovered: sideBottomSurfaces.isRightCenterHovered
        isBottomCenterHovered: sideBottomSurfaces.isBottomCenterHovered
        isBottomRightHovered: sideBottomSurfaces.isBottomRightHovered
        leftCenterArea: sideBottomSurfaces.leftCenterNotchArea
        rightCenterArea: sideBottomSurfaces.rightCenterNotchArea
        bottomCenterArea: sideBottomSurfaces.bottomCenterNotchArea
        bottomRightArea: sideBottomSurfaces.bottomRightNotchArea
    }
    
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "brain-shell-frame"
    WlrLayershell.keyboardFocus: (SurfaceState.activeSurface !== "none" || (ShellState.screenRecord && !ScreenRecService.recording)) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Region {
        id: fullRegion
        x: 0; y: 0
        width: root.width
        height: root.height
    }

    Region {
        id: frameBlurRegion

        // ── Floating Mode Blur Regions (Pills and expanded floating popups) ──
        RoundedRegion {
            rectX: PrefsService.isFloating ? Math.round(floatingShape.leftPillX) : 0
            rectY: PrefsService.isFloating ? Math.round(floatingShape.leftPillY) : 0
            rectWidth: PrefsService.isFloating ? Math.round(floatingShape.leftPillWidth) : 0
            rectHeight: PrefsService.isFloating ? Math.round(floatingShape.leftPillHeight) : 0
            cornerRadius: PrefsService.isFloating ? floatingShape.cornerRadius : 0
        }
        RoundedRegion {
            rectX: PrefsService.isFloating ? Math.round(floatingShape.centerPillX) : 0
            rectY: PrefsService.isFloating ? Math.round(floatingShape.centerPillY) : 0
            rectWidth: PrefsService.isFloating ? Math.round(floatingShape.centerPillWidth) : 0
            rectHeight: PrefsService.isFloating ? Math.round(floatingShape.centerPillHeight) : 0
            cornerRadius: PrefsService.isFloating ? floatingShape.cornerRadius : 0
        }
        RoundedRegion {
            rectX: PrefsService.isFloating ? Math.round(floatingShape.rightPillX) : 0
            rectY: PrefsService.isFloating ? Math.round(floatingShape.rightPillY) : 0
            rectWidth: PrefsService.isFloating ? Math.round(floatingShape.rightPillWidth) : 0
            rectHeight: PrefsService.isFloating ? Math.round(floatingShape.rightPillHeight) : 0
            cornerRadius: PrefsService.isFloating ? floatingShape.cornerRadius : 0
        }

        // Floating side popups (when expanded)
        RoundedRegion {
            rectX: PrefsService.isFloating && SurfaceState.isLeftCenterExpanded ? Math.round(sideBottomSurfaces.leftCenterNotchArea.x) : 0
            rectY: PrefsService.isFloating && SurfaceState.isLeftCenterExpanded ? Math.round(sideBottomSurfaces.leftCenterNotchArea.y) : 0
            rectWidth: PrefsService.isFloating && SurfaceState.isLeftCenterExpanded ? Math.round(sideBottomSurfaces.leftCenterNotchArea.width) : 0
            rectHeight: PrefsService.isFloating && SurfaceState.isLeftCenterExpanded ? Math.round(sideBottomSurfaces.leftCenterNotchArea.height) : 0
            cornerRadius: PrefsService.isFloating ? floatingShape.cornerRadius : 0
        }
        RoundedRegion {
            rectX: PrefsService.isFloating && SurfaceState.isRightCenterExpanded ? Math.round(root.width - sideBottomSurfaces.rightCenterNotchArea.width) : 0
            rectY: PrefsService.isFloating && SurfaceState.isRightCenterExpanded ? Math.round(sideBottomSurfaces.rightCenterNotchArea.y) : 0
            rectWidth: PrefsService.isFloating && SurfaceState.isRightCenterExpanded ? Math.round(sideBottomSurfaces.rightCenterNotchArea.width) : 0
            rectHeight: PrefsService.isFloating && SurfaceState.isRightCenterExpanded ? Math.round(sideBottomSurfaces.rightCenterNotchArea.height) : 0
            cornerRadius: PrefsService.isFloating ? floatingShape.cornerRadius : 0
        }
        RoundedRegion {
            rectX: PrefsService.isFloating && SurfaceState.isBottomCenterExpanded ? Math.round((root.width - sideBottomSurfaces.bottomCenterNotchArea.width) / 2) : 0
            rectY: PrefsService.isFloating && SurfaceState.isBottomCenterExpanded ? Math.round(root.height - sideBottomSurfaces.bottomCenterNotchArea.height) : 0
            rectWidth: PrefsService.isFloating && SurfaceState.isBottomCenterExpanded ? Math.round(sideBottomSurfaces.bottomCenterNotchArea.width) : 0
            rectHeight: PrefsService.isFloating && SurfaceState.isBottomCenterExpanded ? Math.round(sideBottomSurfaces.bottomCenterNotchArea.height) : 0
            cornerRadius: PrefsService.isFloating ? floatingShape.cornerRadius : 0
        }
        RoundedRegion {
            rectX: PrefsService.isFloating && SurfaceState.isBottomRightExpanded ? Math.round(root.width - sideBottomSurfaces.bottomRightNotchArea.width) : 0
            rectY: PrefsService.isFloating && SurfaceState.isBottomRightExpanded ? Math.round(root.height - sideBottomSurfaces.bottomRightNotchArea.height) : 0
            rectWidth: PrefsService.isFloating && SurfaceState.isBottomRightExpanded ? Math.round(sideBottomSurfaces.bottomRightNotchArea.width) : 0
            rectHeight: PrefsService.isFloating && SurfaceState.isBottomRightExpanded ? Math.round(sideBottomSurfaces.bottomRightNotchArea.height) : 0
            cornerRadius: PrefsService.isFloating ? floatingShape.cornerRadius : 0
        }

        // ── Border Mode Blur Regions ──
        // Top and Bottom frame borders
        Region {
            x: 0; y: 0
            width: !PrefsService.isFloating && surfaceShape.frameThickness > 0 ? root.width : 0
            height: !PrefsService.isFloating && surfaceShape.frameThickness > 0 ? surfaceShape.frameThickness : 0
        }
        Region {
            x: 0
            y: !PrefsService.isFloating && surfaceShape.frameThickness > 0 ? root.height - surfaceShape.frameThickness : 0
            width: !PrefsService.isFloating && surfaceShape.frameThickness > 0 ? root.width : 0
            height: !PrefsService.isFloating && surfaceShape.frameThickness > 0 ? surfaceShape.frameThickness : 0
        }

        // Left and Right frame borders
        Region {
            x: 0; y: 0
            width: !PrefsService.isFloating && surfaceShape.frameThickness > 0 ? surfaceShape.frameThickness : 0
            height: !PrefsService.isFloating && surfaceShape.frameThickness > 0 ? root.height : 0
        }
        Region {
            x: !PrefsService.isFloating && surfaceShape.frameThickness > 0 ? root.width - surfaceShape.frameThickness : 0
            y: 0
            width: !PrefsService.isFloating && surfaceShape.frameThickness > 0 ? surfaceShape.frameThickness : 0
            height: !PrefsService.isFloating && surfaceShape.frameThickness > 0 ? root.height : 0
        }

        // Screen Corner Arcs (bottom-left and bottom-right inner frame roundness)
        Region {
            x: 0
            y: !PrefsService.isFloating ? root.height - surfaceShape.frameThickness - surfaceShape.innerRadius : 0
            width: !PrefsService.isFloating ? surfaceShape.frameThickness + surfaceShape.innerRadius : 0
            height: !PrefsService.isFloating ? surfaceShape.frameThickness + surfaceShape.innerRadius : 0

            Region {
                x: surfaceShape.frameThickness
                y: !PrefsService.isFloating ? root.height - surfaceShape.frameThickness - 2 * surfaceShape.innerRadius : 0
                width: !PrefsService.isFloating ? 2 * surfaceShape.innerRadius : 0
                height: !PrefsService.isFloating ? 2 * surfaceShape.innerRadius : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }
        Region {
            x: !PrefsService.isFloating && surfaceShape.brnDepth <= 1 ? root.width - surfaceShape.frameThickness - surfaceShape.innerRadius : 0
            y: !PrefsService.isFloating && surfaceShape.brnDepth <= 1 ? root.height - surfaceShape.frameThickness - surfaceShape.innerRadius : 0
            width: !PrefsService.isFloating && surfaceShape.brnDepth <= 1 ? surfaceShape.frameThickness + surfaceShape.innerRadius : 0
            height: !PrefsService.isFloating && surfaceShape.brnDepth <= 1 ? surfaceShape.frameThickness + surfaceShape.innerRadius : 0

            Region {
                x: !PrefsService.isFloating ? root.width - surfaceShape.frameThickness - 2 * surfaceShape.innerRadius : 0
                y: !PrefsService.isFloating ? root.height - surfaceShape.frameThickness - 2 * surfaceShape.innerRadius : 0
                width: !PrefsService.isFloating ? 2 * surfaceShape.innerRadius : 0
                height: !PrefsService.isFloating ? 2 * surfaceShape.innerRadius : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }

        // Top Center Notch (Dashboard & top-center notch body + bottom corners)
        RoundedRegion {
            rectX: !PrefsService.isFloating ? Math.round(root.width / 2 - surfaceShape.centerNotchWidth / 2) : 0
            rectY: 0
            rectWidth: !PrefsService.isFloating ? Math.round(surfaceShape.centerNotchWidth) : 0
            rectHeight: !PrefsService.isFloating ? Math.round(surfaceShape.frameThickness + surfaceShape.centerNotchHeight) : 0
            cornerRadius: !PrefsService.isFloating ? Math.round(surfaceShape.cnR) : 0
            roundTopLeft: false
            roundTopRight: false
            roundBottomLeft: true
            roundBottomRight: true
        }

        // Center Notch Left Concave Flare
        Region {
            x: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(root.width / 2 - surfaceShape.centerNotchWidth / 2 - surfaceShape.cnFr) : 0
            y: 0
            width: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(surfaceShape.cnFr) : 0
            height: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.cnFr) : 0

            Region {
                x: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(root.width / 2 - surfaceShape.centerNotchWidth / 2 - 2 * surfaceShape.cnFr) : 0
                y: surfaceShape.frameThickness
                width: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(2 * surfaceShape.cnFr) : 0
                height: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(2 * surfaceShape.cnFr) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }

        // Center Notch Right Concave Flare
        Region {
            x: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(root.width / 2 + surfaceShape.centerNotchWidth / 2) : 0
            y: 0
            width: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(surfaceShape.cnFr) : 0
            height: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.cnFr) : 0

            Region {
                x: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(root.width / 2 + surfaceShape.centerNotchWidth / 2) : 0
                y: surfaceShape.frameThickness
                width: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(2 * surfaceShape.cnFr) : 0
                height: !PrefsService.isFloating && surfaceShape.cnFr > 0 ? Math.round(2 * surfaceShape.cnFr) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }

        // Top Right Notch (Body + bottom-left rounded corner)
        RoundedRegion {
            rectX: !PrefsService.isFloating ? Math.round(root.width - surfaceShape.frameThickness - surfaceShape.rightNotchWidth) : 0
            rectY: 0
            rectWidth: !PrefsService.isFloating ? Math.round(surfaceShape.frameThickness + surfaceShape.rightNotchWidth) : 0
            rectHeight: !PrefsService.isFloating ? Math.round(surfaceShape.frameThickness + surfaceShape.rightNotchHeight) : 0
            cornerRadius: !PrefsService.isFloating ? Math.round(surfaceShape.rnInnerR) : 0
            roundTopLeft: false
            roundTopRight: false
            roundBottomLeft: true
            roundBottomRight: false
        }

        // Right Notch Left Concave Flare
        Region {
            x: !PrefsService.isFloating && surfaceShape.rnTopFlare > 0 ? Math.round(root.width - surfaceShape.frameThickness - surfaceShape.rightNotchWidth - surfaceShape.rnTopFlare) : 0
            y: 0
            width: !PrefsService.isFloating && surfaceShape.rnTopFlare > 0 ? Math.round(surfaceShape.rnTopFlare) : 0
            height: !PrefsService.isFloating && surfaceShape.rnTopFlare > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.rnTopFlare) : 0

            Region {
                x: !PrefsService.isFloating && surfaceShape.rnTopFlare > 0 ? Math.round(root.width - surfaceShape.frameThickness - surfaceShape.rightNotchWidth - 2 * surfaceShape.rnTopFlare) : 0
                y: surfaceShape.frameThickness
                width: !PrefsService.isFloating && surfaceShape.rnTopFlare > 0 ? Math.round(2 * surfaceShape.rnTopFlare) : 0
                height: !PrefsService.isFloating && surfaceShape.rnTopFlare > 0 ? Math.round(2 * surfaceShape.rnTopFlare) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }

        // Right Notch Bottom Concave Melt
        Region {
            x: !PrefsService.isFloating && surfaceShape.rnBottomMelt > 0 ? Math.round(root.width - surfaceShape.frameThickness - surfaceShape.rnBottomMelt) : 0
            y: !PrefsService.isFloating && surfaceShape.rnBottomMelt > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.rightNotchHeight) : 0
            width: !PrefsService.isFloating && surfaceShape.rnBottomMelt > 0 ? Math.round(surfaceShape.rnBottomMelt) : 0
            height: !PrefsService.isFloating && surfaceShape.rnBottomMelt > 0 ? Math.round(surfaceShape.rnBottomMelt) : 0

            Region {
                x: !PrefsService.isFloating && surfaceShape.rnBottomMelt > 0 ? Math.round(root.width - surfaceShape.frameThickness - 2 * surfaceShape.rnBottomMelt) : 0
                y: !PrefsService.isFloating && surfaceShape.rnBottomMelt > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.rightNotchHeight) : 0
                width: !PrefsService.isFloating && surfaceShape.rnBottomMelt > 0 ? Math.round(2 * surfaceShape.rnBottomMelt) : 0
                height: !PrefsService.isFloating && surfaceShape.rnBottomMelt > 0 ? Math.round(2 * surfaceShape.rnBottomMelt) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }

        // Top Left Notch (Body + bottom-right rounded corner)
        RoundedRegion {
            rectX: 0
            rectY: 0
            rectWidth: !PrefsService.isFloating ? Math.round(surfaceShape.frameThickness + surfaceShape.leftNotchWidth) : 0
            rectHeight: !PrefsService.isFloating ? Math.round(surfaceShape.frameThickness + surfaceShape.leftNotchHeight) : 0
            cornerRadius: !PrefsService.isFloating ? Math.round(surfaceShape.lnInnerR) : 0
            roundTopLeft: false
            roundTopRight: false
            roundBottomLeft: false
            roundBottomRight: true
        }

        // Left Notch Right Concave Flare
        Region {
            x: !PrefsService.isFloating && surfaceShape.lnRightFlare > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.leftNotchWidth) : 0
            y: 0
            width: !PrefsService.isFloating && surfaceShape.lnRightFlare > 0 ? Math.round(surfaceShape.lnRightFlare) : 0
            height: !PrefsService.isFloating && surfaceShape.lnRightFlare > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.lnRightFlare) : 0

            Region {
                x: !PrefsService.isFloating && surfaceShape.lnRightFlare > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.leftNotchWidth) : 0
                y: surfaceShape.frameThickness
                width: !PrefsService.isFloating && surfaceShape.lnRightFlare > 0 ? Math.round(2 * surfaceShape.lnRightFlare) : 0
                height: !PrefsService.isFloating && surfaceShape.lnRightFlare > 0 ? Math.round(2 * surfaceShape.lnRightFlare) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }

        // Left Notch Bottom Concave Melt
        Region {
            x: surfaceShape.frameThickness
            y: !PrefsService.isFloating && surfaceShape.lnLeftMelt > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.leftNotchHeight) : 0
            width: !PrefsService.isFloating && surfaceShape.lnLeftMelt > 0 ? Math.round(surfaceShape.lnLeftMelt) : 0
            height: !PrefsService.isFloating && surfaceShape.lnLeftMelt > 0 ? Math.round(surfaceShape.lnLeftMelt) : 0

            Region {
                x: !PrefsService.isFloating && surfaceShape.lnLeftMelt > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.lnLeftMelt) : 0
                y: !PrefsService.isFloating && surfaceShape.lnLeftMelt > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.leftNotchHeight) : 0
                width: !PrefsService.isFloating && surfaceShape.lnLeftMelt > 0 ? Math.round(2 * surfaceShape.lnLeftMelt) : 0
                height: !PrefsService.isFloating && surfaceShape.lnLeftMelt > 0 ? Math.round(2 * surfaceShape.lnLeftMelt) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }

        // Side Notches (Only blur when expanded)
        // Left Center Notch (Arch Menu)
        RoundedRegion {
            rectX: 0
            rectY: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 ? Math.round((root.height - surfaceShape.lcnHeight) / 2) : 0
            rectWidth: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 ? Math.round(surfaceShape.frameThickness + surfaceShape.lcnDepth) : 0
            rectHeight: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 ? Math.round(surfaceShape.lcnHeight) : 0
            cornerRadius: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 ? Math.round(surfaceShape.lcnR) : 0
            roundTopLeft: false
            roundBottomLeft: false
            roundTopRight: true
            roundBottomRight: true
        }
        Region {
            x: 0
            y: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round((root.height - surfaceShape.lcnHeight) / 2 - surfaceShape.lcnFr) : 0
            width: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.lcnFr) : 0
            height: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round(surfaceShape.lcnFr) : 0

            Region {
                x: surfaceShape.frameThickness
                y: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round((root.height - surfaceShape.lcnHeight) / 2 - 2 * surfaceShape.lcnFr) : 0
                width: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round(2 * surfaceShape.lcnFr) : 0
                height: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round(2 * surfaceShape.lcnFr) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }
        Region {
            x: 0
            y: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round((root.height + surfaceShape.lcnHeight) / 2) : 0
            width: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.lcnFr) : 0
            height: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round(surfaceShape.lcnFr) : 0

            Region {
                x: surfaceShape.frameThickness
                y: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round((root.height + surfaceShape.lcnHeight) / 2) : 0
                width: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round(2 * surfaceShape.lcnFr) : 0
                height: !PrefsService.isFloating && surfaceShape.lcnDepth > 1 && surfaceShape.lcnFr > 0 ? Math.round(2 * surfaceShape.lcnFr) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }

        // Right Center Notch (Audio / Quick Control)
        RoundedRegion {
            rectX: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 ? Math.round(root.width - surfaceShape.frameThickness - surfaceShape.rcnDepth) : 0
            rectY: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 ? Math.round((root.height - surfaceShape.rcnHeight) / 2) : 0
            rectWidth: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 ? Math.round(surfaceShape.frameThickness + surfaceShape.rcnDepth) : 0
            rectHeight: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 ? Math.round(surfaceShape.rcnHeight) : 0
            cornerRadius: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 ? Math.round(surfaceShape.rcnR) : 0
            roundTopRight: false
            roundBottomRight: false
            roundTopLeft: true
            roundBottomLeft: true
        }
        Region {
            x: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(root.width - surfaceShape.frameThickness - surfaceShape.rcnFr) : 0
            y: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round((root.height - surfaceShape.rcnHeight) / 2 - surfaceShape.rcnFr) : 0
            width: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.rcnFr) : 0
            height: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(surfaceShape.rcnFr) : 0

            Region {
                x: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(root.width - surfaceShape.frameThickness - 2 * surfaceShape.rcnFr) : 0
                y: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round((root.height - surfaceShape.rcnHeight) / 2 - 2 * surfaceShape.rcnFr) : 0
                width: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(2 * surfaceShape.rcnFr) : 0
                height: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(2 * surfaceShape.rcnFr) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }
        Region {
            x: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(root.width - surfaceShape.frameThickness - surfaceShape.rcnFr) : 0
            y: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round((root.height + surfaceShape.rcnHeight) / 2) : 0
            width: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.rcnFr) : 0
            height: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(surfaceShape.rcnFr) : 0

            Region {
                x: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(root.width - surfaceShape.frameThickness - 2 * surfaceShape.rcnFr) : 0
                y: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round((root.height + surfaceShape.rcnHeight) / 2) : 0
                width: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(2 * surfaceShape.rcnFr) : 0
                height: !PrefsService.isFloating && surfaceShape.rcnDepth > 1 && surfaceShape.rcnFr > 0 ? Math.round(2 * surfaceShape.rcnFr) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }

        // Bottom Center Notch (Wallpaper Popup)
        RoundedRegion {
            rectX: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 ? Math.round((root.width - surfaceShape.bcnWidth) / 2) : 0
            rectY: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 ? Math.round(root.height - surfaceShape.frameThickness - surfaceShape.bcnDepth) : 0
            rectWidth: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 ? Math.round(surfaceShape.bcnWidth) : 0
            rectHeight: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 ? Math.round(surfaceShape.frameThickness + surfaceShape.bcnDepth) : 0
            cornerRadius: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 ? Math.round(surfaceShape.bcnR) : 0
            roundBottomLeft: false
            roundBottomRight: false
            roundTopLeft: true
            roundTopRight: true
        }
        Region {
            x: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round((root.width - surfaceShape.bcnWidth) / 2 - surfaceShape.bcnFr) : 0
            y: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(root.height - surfaceShape.frameThickness - surfaceShape.bcnFr) : 0
            width: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(surfaceShape.bcnFr) : 0
            height: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.bcnFr) : 0

            Region {
                x: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round((root.width - surfaceShape.bcnWidth) / 2 - 2 * surfaceShape.bcnFr) : 0
                y: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(root.height - surfaceShape.frameThickness - 2 * surfaceShape.bcnFr) : 0
                width: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(2 * surfaceShape.bcnFr) : 0
                height: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(2 * surfaceShape.bcnFr) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }
        Region {
            x: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round((root.width + surfaceShape.bcnWidth) / 2) : 0
            y: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(root.height - surfaceShape.frameThickness - surfaceShape.bcnFr) : 0
            width: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(surfaceShape.bcnFr) : 0
            height: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(surfaceShape.frameThickness + surfaceShape.bcnFr) : 0

            Region {
                x: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round((root.width + surfaceShape.bcnWidth) / 2) : 0
                y: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(root.height - surfaceShape.frameThickness - 2 * surfaceShape.bcnFr) : 0
                width: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(2 * surfaceShape.bcnFr) : 0
                height: !PrefsService.isFloating && surfaceShape.bcnDepth > 1 && surfaceShape.bcnFr > 0 ? Math.round(2 * surfaceShape.bcnFr) : 0
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
            }
        }

        // Bottom Right Notch (Clipboard Popup)
        RoundedRegion {
            rectX: !PrefsService.isFloating && surfaceShape.brnDepth > 1 ? Math.round(root.width - surfaceShape.frameThickness - surfaceShape.brnWidth) : 0
            rectY: !PrefsService.isFloating && surfaceShape.brnDepth > 1 ? Math.round(root.height - surfaceShape.frameThickness - surfaceShape.brnDepth) : 0
            rectWidth: !PrefsService.isFloating && surfaceShape.brnDepth > 1 ? Math.round(surfaceShape.frameThickness + surfaceShape.brnWidth) : 0
            rectHeight: !PrefsService.isFloating && surfaceShape.brnDepth > 1 ? Math.round(surfaceShape.frameThickness + surfaceShape.brnDepth) : 0
            cornerRadius: !PrefsService.isFloating && surfaceShape.brnDepth > 1 ? Math.round(surfaceShape.brnInnerR) : 0
            roundBottomRight: false
            roundBottomLeft: false
            roundTopLeft: true
            roundTopRight: false
        }
    }

    // Pass the blur region to the compositor.
    // On Hyprland, ignorealpha 0.1 restricts fullRegion blur to non-transparent pixels.
    // On Niri/other compositors, frameBlurRegion blurs only the frame borders and active notches/popups.
    BackgroundEffect.blurRegion: PrefsService.bgBlur ? (WM.name === "Hyprland" ? fullRegion : frameBlurRegion) : null

    // Mask logic: Combine frame borders + active notches + click shield + edge handles. 
    mask: Region {
        Region { item: clickShield.isActive ? clickShield : null }
        
        // Top and Bottom frame borders (Border & Hybrid modes)
        Region { x: 0; y: 0; width: PrefsService.isFloating ? 0 : root.width; height: PrefsService.isFloating ? 0 : Math.max(1, surfaceShape.frameThickness) }
        Region { x: 0; y: root.height - (PrefsService.isFloating ? 0 : Math.max(1, surfaceShape.frameThickness)); width: PrefsService.isFloating ? 0 : root.width; height: PrefsService.isFloating ? 0 : Math.max(1, surfaceShape.frameThickness) }
        
        // Left and Right frame borders (Border & Hybrid modes)
        Region { x: 0; y: 0; width: PrefsService.isFloating ? 0 : Math.max(1, surfaceShape.frameThickness); height: PrefsService.isFloating ? 0 : root.height }
        Region { x: root.width - (PrefsService.isFloating ? 0 : Math.max(1, surfaceShape.frameThickness)); y: 0; width: PrefsService.isFloating ? 0 : Math.max(1, surfaceShape.frameThickness); height: PrefsService.isFloating ? 0 : root.height }
        
        // Top Notches (Border & Hybrid idle notches)
        Region { x: 0; y: 0; width: PrefsService.isFloating ? 0 : surfaceShape.leftNotchWidth; height: PrefsService.isFloating ? 0 : surfaceShape.leftNotchHeight }
        Region { x: Math.round(root.width / 2 - surfaceShape.centerNotchWidth / 2); y: 0; width: PrefsService.isFloating ? 0 : surfaceShape.centerNotchWidth; height: PrefsService.isFloating ? 0 : surfaceShape.centerNotchHeight }
        Region { x: Math.round(root.width - surfaceShape.rightNotchWidth); y: 0; width: PrefsService.isFloating ? 0 : surfaceShape.rightNotchWidth; height: PrefsService.isFloating ? 0 : surfaceShape.rightNotchHeight }

        // Top Pill Areas (Floating mode)
        Region { item: PrefsService.isFloating ? leftNotchArea : null }
        Region { item: PrefsService.isFloating ? centerNotchArea : null }
        Region { item: PrefsService.isFloating ? rightNotchArea : null }

        // Top Center & Top Right Popups when active
        Region { item: SurfaceState.isTopExpanded ? dashboardContainer : null }
        Region { item: (SurfaceState.isRightExpanded || Popups.notificationToastOpen) ? rightPopupContainer : null }

        // 1px Edge Fallback Triggers (Always Active on All 4 Screen Edges for Mouse Access)
        Region { x: Math.round(root.width / 2 - (160 * root.localScale) / 2); y: 0; width: Math.round(160 * root.localScale); height: 1 }
        Region { 
            x: PrefsService.isFloating ? Math.round(floatingShape.leftPillX) : 0
            y: 0
            width: PrefsService.isFloating ? Math.round(floatingShape.leftPillIdleWidth) : 0
            height: (PrefsService.isFloating && ShellState.focusMode && PrefsService.focusModeHoverExpand) ? 1 : 0 
        }
        Region { 
            x: PrefsService.isFloating ? Math.round(floatingShape.rightPillX) : 0
            y: 0
            width: PrefsService.isFloating ? Math.round(floatingShape.rightPillIdleWidth) : 0
            height: (PrefsService.isFloating && ShellState.focusMode && PrefsService.focusModeHoverExpand) ? 1 : 0 
        }
        Region { x: 0; y: Math.round(root.height / 2 - (200 * root.localScale) / 2); width: 1; height: Math.round(200 * root.localScale) }
        Region { x: root.width - 1; y: Math.round(root.height / 2 - (200 * root.localScale) / 2); width: 1; height: Math.round(200 * root.localScale) }
        Region { x: Math.round(root.width / 2 - (300 * root.localScale) / 2); y: root.height - 1; width: Math.round(300 * root.localScale); height: 1 }
        Region { x: root.width - Math.round(200 * root.localScale); y: root.height - 1; width: Math.round(200 * root.localScale); height: 1 }

        // Side & Bottom Notch Areas when expanded
        Region { item: SurfaceState.isLeftCenterExpanded ? sideBottomSurfaces.leftCenterNotchArea : null }
        Region { item: SurfaceState.isRightCenterExpanded ? sideBottomSurfaces.rightCenterNotchArea : null }
        Region { item: SurfaceState.isBottomCenterExpanded ? sideBottomSurfaces.bottomCenterNotchArea : null }
        Region { item: SurfaceState.isBottomRightExpanded ? sideBottomSurfaces.bottomRightNotchArea : null }
    }

    // --- FOCUS & FALLBACK TRIGGERS ---
    FocusTriggers {
        id: focusTriggers
        anchors.fill: parent
        localScale: root.localScale
        leftContent: leftContent
        centerContent: centerContent
        rightContent: rightContent
    }

    SurfaceShape {
        id: surfaceShape
        anchors.fill: parent
        localScale: root.localScale
        visible: !PrefsService.isFloating
        
        rcnDepth: { 
            if (!SurfaceState.isRightCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "audio") return sideBottomSurfaces.audioPopupView.popupWidth; 
            if (SurfaceState.activeContent === "quick") return sideBottomSurfaces.quickControlPopupView.popupWidth; 
            return Math.round(Theme.popupMaxWidth * root.localScale); 
        } 
        rcnHeight: { 
            if (!SurfaceState.isRightCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "audio") return sideBottomSurfaces.audioPopupView.popupHeight; 
            if (SurfaceState.activeContent === "quick") return sideBottomSurfaces.quickControlPopupView.popupHeight; 
            return Math.round(Theme.popupMaxHeight * root.localScale); 
        }
        brnWidth: {
            if (!SurfaceState.isBottomRightExpanded) return innerRadius;
            if (SurfaceState.activeContent === "clipboard") return sideBottomSurfaces.clipboardPopupView.popupWidth + Math.round(Theme.cornerRadius * root.localScale);
            return Math.round(Theme.popupMaxWidth * root.localScale);
        }
        lcnDepth: { 
            if (!SurfaceState.isLeftCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "archMenu") return sideBottomSurfaces.archMenuPopupView.popupWidth + Math.round(Theme.cornerRadius * root.localScale); 
            return Math.round(Theme.popupMaxWidth * root.localScale); 
        } 
        lcnHeight: { 
            if (!SurfaceState.isLeftCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "archMenu") return sideBottomSurfaces.archMenuPopupView.popupHeight + Math.round(Theme.cornerRadius * root.localScale * 2); 
            return Math.round(Theme.popupMaxHeight * root.localScale); 
        }
        bcnWidth: { 
            if (!SurfaceState.isBottomCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "wallpaper") return sideBottomSurfaces.wallpaperPopupView.popupWidth + Math.round(Theme.cornerRadius * root.localScale * 2); 
            return Math.round(Theme.popupMaxWidth * root.localScale); 
        } 
        bcnDepth: { 
            if (!SurfaceState.isBottomCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "wallpaper") return sideBottomSurfaces.wallpaperPopupView.popupHeight + Math.round(Theme.cornerRadius * root.localScale); 
            return Math.round(Theme.popupMaxHeight * root.localScale); 
        }
        brnDepth: {
            if (!SurfaceState.isBottomRightExpanded) return 0.001;
            if (SurfaceState.activeContent === "clipboard") return sideBottomSurfaces.clipboardPopupView.popupHeight + Math.round(Theme.cornerRadius * root.localScale);
            return Math.round(Theme.popupMaxHeight * root.localScale);
        }
        
        leftNotchWidth: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (focusTriggers.fmLeftHovered || leftNotchHover.hovered))) ? 0.001 : Math.max(Math.round(Theme.lNotchMinWidth * localScale), Math.min(Math.round(Theme.lNotchMaxWidth * localScale), leftContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale)))
        leftNotchHeight: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (focusTriggers.fmLeftHovered || leftNotchHover.hovered))) ? surfaceShape.innerRadius : Math.round(Theme.notchHeight * root.localScale)
        centerNotchWidth: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (focusTriggers.fmCenterHovered || centerNotchHover.hovered)) && !SurfaceState.isTopExpanded && !ShellState.screenRecord && !ScreenRecService.recording && !Popups.miniPlayerOpen) ? 0.001 : (SurfaceState.isTopExpanded ? Math.round(Popups.dashboardPageWidth * root.localScale) : Math.max(Math.round(Theme.cNotchMinWidth * localScale), Math.min(Math.round(Theme.cNotchMaxWidth * localScale), centerContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale))))
        centerNotchHeight: {
            if (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (focusTriggers.fmCenterHovered || centerNotchHover.hovered)) && !SurfaceState.isTopExpanded && !ShellState.screenRecord && !ScreenRecService.recording && !Popups.miniPlayerOpen) return 0.001;
            if (SurfaceState.isTopExpanded) return Math.round(Theme.dashboardHeight * root.localScale);
            if (Popups.miniPlayerOpen) return Math.round(Theme.notchHeight * root.localScale) + miniPlayerView.height + Math.round(16 * root.localScale);
            if (ShellState.screenRecord && !ScreenRecService.recording && ScreenRecService.optionsExpanded) return Math.round(Theme.notchHeight * root.localScale) + screenRecOptionsPopupView.height + Math.round(16 * root.localScale);
            return Math.round(Theme.notchHeight * root.localScale);
        }
        rightNotchWidth: {
            if (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (focusTriggers.fmRightHovered || rightNotchHover.hovered)) && !SurfaceState.isRightExpanded && !Popups.notificationToastOpen) return 0.001;
            if (!SurfaceState.isRightExpanded) {
                if (Popups.notificationToastOpen) return notificationToastView.toastWidth + Math.round(Theme.cornerRadius * root.localScale);
                return Math.max(Math.round(Theme.rNotchMinWidth * localScale), Math.min(Math.round(Theme.rNotchMaxWidth * localScale), rightContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale)));
            }
            if (SurfaceState.activeContent === "network") return Math.round(Theme.networkPopupWidth * root.localScale) + Math.round(Theme.cornerRadius * root.localScale);
            if (SurfaceState.activeContent === "notifications") return notifsPopupView.popupWidth + Math.round(Theme.cornerRadius * root.localScale);
            return Math.round(Theme.popupMaxWidth * root.localScale);
        }
        rightNotchHeight: {
            if (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (focusTriggers.fmRightHovered || rightNotchHover.hovered)) && !SurfaceState.isRightExpanded && !Popups.notificationToastOpen) return surfaceShape.innerRadius;
            if (!SurfaceState.isRightExpanded) {
                if (Popups.notificationToastOpen) return notificationToastView.targetHeight;
                return Math.round(Theme.notchHeight * root.localScale);
            }
            if (SurfaceState.activeContent === "network") return Math.round(648 * root.localScale);
            if (SurfaceState.activeContent === "notifications") return notifsPopupView.targetHeight;
            return Math.round(Theme.popupMaxHeight * root.localScale);
        }
        
        // Geometry animates with smooth CUBIC curve (never detaches)
    }

    FloatingShape {
        id: floatingShape
        anchors.fill: parent
        localScale: root.localScale
        visible: PrefsService.isFloating
        leftContentWidth: leftContent.implicitWidth
        centerContentWidth: centerContent.implicitWidth
        rightContentWidth: rightContent.implicitWidth

        isLeftHovered: focusTriggers.fmLeftHovered || leftNotchHover.hovered
        isCenterHovered: focusTriggers.fmCenterHovered || centerNotchHover.hovered
        isRightHovered: focusTriggers.fmRightHovered || rightNotchHover.hovered

        isCenterExpanded: SurfaceState.isTopExpanded || Popups.miniPlayerOpen || (ShellState.screenRecord && !ScreenRecService.recording && ScreenRecService.optionsExpanded)
        centerExpandedWidth: {
            if (SurfaceState.isTopExpanded) return Math.round(Popups.dashboardPageWidth * root.localScale);
            return floatingShape.centerPillIdleWidth;
        }
        centerExpandedHeight: {
            if (SurfaceState.isTopExpanded) return Math.round(Theme.dashboardHeight * root.localScale);
            if (Popups.miniPlayerOpen) return floatingShape.barHeight + miniPlayerView.height + Math.round(16 * root.localScale);
            if (ShellState.screenRecord && !ScreenRecService.recording && ScreenRecService.optionsExpanded) return floatingShape.barHeight + screenRecOptionsPopupView.height + Math.round(16 * root.localScale);
            return floatingShape.barHeight;
        }

        isRightExpanded: SurfaceState.isRightExpanded || Popups.notificationToastOpen
        rightExpandedWidth: {
            if (SurfaceState.isRightExpanded) {
                if (SurfaceState.activeContent === "network") return Math.round(Theme.networkPopupWidth * root.localScale);
                if (SurfaceState.activeContent === "notifications") return notifsPopupView.popupWidth;
                return Math.round(Theme.popupMaxWidth * root.localScale);
            }
            if (Popups.notificationToastOpen) return notificationToastView.toastWidth + Math.round(Theme.cornerRadius * root.localScale);
            return floatingShape.rightPillIdleWidth;
        }
        rightExpandedHeight: {
            if (SurfaceState.isRightExpanded) {
                if (SurfaceState.activeContent === "network") return Math.round(648 * root.localScale);
                if (SurfaceState.activeContent === "notifications") return notifsPopupView.targetHeight;
                return Math.round(Theme.popupMaxHeight * root.localScale);
            }
            if (Popups.notificationToastOpen) return notificationToastView.targetHeight;
            return floatingShape.barHeight;
        }
    }
    
    
    // --- NOTCH CONTENT ---
    Item {
        id: leftNotchArea
        HoverHandler { id: leftNotchHover }
        width: PrefsService.isFloating ? floatingShape.leftPillWidth : surfaceShape.leftNotchWidth
        height: PrefsService.isFloating ? floatingShape.leftPillHeight : surfaceShape.leftNotchHeight
        anchors.left: parent.left
        anchors.leftMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
        anchors.top: parent.top
        anchors.topMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
        clip: true
        
        opacity: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (focusTriggers.fmLeftHovered || leftNotchHover.hovered)) && !SurfaceState.isTopExpanded) ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        
        Item {
            id: leftNotchHead
            width: parent.width
            height: PrefsService.isFloating ? floatingShape.barHeight : Math.round(Theme.notchHeight * root.localScale)
            anchors.top: parent.top
            
            LeftContent {
                localScale: root.localScale
                id: leftContent
                anchors.centerIn: parent
            }
        }
    }

    Item {
        id: centerNotchArea
        HoverHandler { id: centerNotchHover }
        width: PrefsService.isFloating ? floatingShape.centerPillWidth : surfaceShape.centerNotchWidth
        height: PrefsService.isFloating ? floatingShape.centerPillHeight : surfaceShape.centerNotchHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
        clip: true
        
        opacity: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (focusTriggers.fmCenterHovered || centerNotchHover.hovered)) && !SurfaceState.isTopExpanded && !ShellState.screenRecord && !ScreenRecService.recording) ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        
        Item {
            id: centerNotchHead
            width: parent.width
            height: PrefsService.isFloating ? floatingShape.barHeight : Math.round(Theme.notchHeight * root.localScale)
            anchors.top: parent.top
            opacity: SurfaceState.isTopExpanded ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.fast } }
            
            CenterContent {
                localScale: root.localScale
                id: centerContent
                anchors.centerIn: parent
            }
        }

        ScreenRecOptionsPopup {
            id: screenRecOptionsPopupView
            localScale: root.localScale
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: centerNotchHead.bottom
            anchors.topMargin: Math.round(8 * root.localScale)
            z: 999
        }
        MiniPlayer {
            id: miniPlayerView
            localScale: root.localScale
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: centerNotchHead.bottom
            anchors.topMargin: Math.round(8 * root.localScale)
            z: 998
        }
    }

    Item {
        id: dashboardContainer
        HoverHandler { id: dashboardHover }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 0
        width: PrefsService.isFloating ? floatingShape.centerPillWidth : surfaceShape.centerNotchWidth
        height: (PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)) + (PrefsService.isFloating ? floatingShape.centerPillHeight : surfaceShape.centerNotchHeight)
        clip: true
        visible: SurfaceState.isTopExpanded || dashboardView.opacity > 0

        Dashboard {
            id: dashboardView
            localScale: root.localScale
            anchors.fill: parent
            anchors.topMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
            screen: root.screen
            
            opacity: SurfaceState.activeContent === "dashboard" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }
    }

    Item {
        id: rightNotchArea
        HoverHandler { id: rightNotchHover }
        width: PrefsService.isFloating ? floatingShape.rightPillWidth : surfaceShape.rightNotchWidth
        height: PrefsService.isFloating ? floatingShape.rightPillHeight : surfaceShape.rightNotchHeight
        anchors.right: parent.right
        anchors.rightMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
        anchors.top: parent.top
        anchors.topMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
        clip: true
        
        opacity: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (focusTriggers.fmRightHovered || rightNotchHover.hovered)) && !SurfaceState.isRightExpanded && !Popups.notificationToastOpen) ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        
        Item {
            id: rightNotchHead
            width: parent.width
            height: PrefsService.isFloating ? floatingShape.barHeight : Math.round(Theme.notchHeight * root.localScale)
            anchors.top: parent.top
            opacity: (SurfaceState.isRightExpanded || Popups.notificationToastOpen) ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.fast } }
            
            RightContent {
                localScale: root.localScale
                id: rightContent
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Math.round(Theme.notchPadding * root.localScale)
            }
        }
    }

    Item {
        id: rightPopupContainer
        HoverHandler { id: rightPopupHover }
        anchors.right: parent.right
        anchors.top: parent.top
        width: (PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)) + (PrefsService.isFloating ? floatingShape.rightPillWidth : surfaceShape.rightNotchWidth)
        height: (PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)) + (PrefsService.isFloating ? floatingShape.rightPillHeight : surfaceShape.rightNotchHeight)
        clip: true
        visible: SurfaceState.isRightExpanded || Popups.notificationToastOpen || networkPopupView.opacity > 0 || notifsPopupView.opacity > 0 || notificationToastView.opacity > 0

        NetworkPopup {
            id: networkPopupView
            localScale: root.localScale
            anchors.fill: parent
            anchors.topMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
            anchors.rightMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
            screen: root.screen

            opacity: SurfaceState.activeContent === "network" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }

        NotificationsPopup {
            id: notifsPopupView
            localScale: root.localScale
            anchors.fill: parent
            anchors.topMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
            anchors.rightMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)

            opacity: SurfaceState.activeContent === "notifications" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }

        NotificationToast {
            id: notificationToastView
            localScale: root.localScale
            anchors.fill: parent
            anchors.topMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
            anchors.rightMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)

            opacity: Popups.notificationToastOpen && !Popups.notificationsOpen ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }
    }

    // --- SIDE & BOTTOM SURFACES ---
    SideBottomSurfaces {
        id: sideBottomSurfaces
        anchors.fill: parent
        localScale: root.localScale
        surfaceShape: surfaceShape
        floatingShape: floatingShape
    }
}