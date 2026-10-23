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
import "../"
import "../theme"
import "../popups"

Item {
    id: sideBottomSurfaces

    required property real localScale
    required property QtObject surfaceShape

    // Notch Area Items
    readonly property alias leftCenterNotchArea: leftCenterNotchArea
    readonly property alias rightCenterNotchArea: rightCenterNotchArea
    readonly property alias bottomCenterNotchArea: bottomCenterNotchArea
    readonly property alias bottomRightNotchArea: bottomRightNotchArea

    // Hover Handlers
    readonly property alias leftCenterNotchHover: leftCenterNotchHover
    readonly property alias rightCenterNotchHover: rightCenterNotchHover
    readonly property alias bottomCenterNotchHover: bottomCenterNotchHover
    readonly property alias bottomRightNotchHover: bottomRightNotchHover

    // Hover Properties
    readonly property alias isLeftCenterHovered: leftCenterNotchHover.hovered
    readonly property alias isRightCenterHovered: rightCenterNotchHover.hovered
    readonly property alias isBottomCenterHovered: bottomCenterNotchHover.hovered
    readonly property alias isBottomRightHovered: bottomRightNotchHover.hovered

    // Popup Views
    readonly property alias archMenuPopupView: archMenuPopupView
    readonly property alias audioPopupView: audioPopupView
    readonly property alias quickControlPopupView: quickControlPopupView
    readonly property alias wallpaperPopupView: wallpaperPopupView
    readonly property alias clipboardPopupView: clipboardPopupView

    Item {
        id: leftCenterNotchArea
        HoverHandler { id: leftCenterNotchHover }
        width: surfaceShape.lcnDepth
        height: surfaceShape.lcnHeight
        anchors.left: parent.left
        anchors.leftMargin: Math.round(Theme.borderWidth * sideBottomSurfaces.localScale)
        anchors.verticalCenter: parent.verticalCenter

        ArchMenu {
            id: archMenuPopupView
            localScale: sideBottomSurfaces.localScale
            anchors.fill: parent
            opacity: SurfaceState.activeContent === "archMenu" ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }
    }

    Item {
        id: rightCenterNotchArea
        HoverHandler { id: rightCenterNotchHover }
        width: surfaceShape.rcnDepth
        height: surfaceShape.rcnHeight
        anchors.right: parent.right
        anchors.rightMargin: Math.round(Theme.borderWidth * sideBottomSurfaces.localScale)
        anchors.verticalCenter: parent.verticalCenter

        AudioPopup {
            id: audioPopupView
            localScale: sideBottomSurfaces.localScale
            anchors.fill: parent
            opacity: SurfaceState.activeContent === "audio" ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }

        QuickControl {
            id: quickControlPopupView
            localScale: sideBottomSurfaces.localScale
            anchors.fill: parent
            opacity: SurfaceState.activeContent === "quick" ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }
    }

    Item {
        id: bottomCenterNotchArea
        HoverHandler { id: bottomCenterNotchHover }
        width: surfaceShape.bcnWidth
        height: surfaceShape.bcnDepth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(Theme.borderWidth * sideBottomSurfaces.localScale)

        WallpaperPopup {
            id: wallpaperPopupView
            localScale: sideBottomSurfaces.localScale
            anchors.fill: parent
            opacity: SurfaceState.activeContent === "wallpaper" ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }
    }

    Item {
        id: bottomRightNotchArea
        HoverHandler { id: bottomRightNotchHover }
        width: surfaceShape.brnWidth
        height: surfaceShape.brnDepth
        anchors.right: parent.right
        anchors.rightMargin: Math.round(Theme.borderWidth * sideBottomSurfaces.localScale)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(Theme.borderWidth * sideBottomSurfaces.localScale)

        ClipboardPopup {
            id: clipboardPopupView
            localScale: sideBottomSurfaces.localScale
            anchors.fill: parent
            opacity: SurfaceState.activeContent === "clipboard" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }
    }
}
