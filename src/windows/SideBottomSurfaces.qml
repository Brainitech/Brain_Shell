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
import "../services"
import "../popups"

Item {
    id: sideBottomSurfaces

    required property real localScale
    required property QtObject surfaceShape
    property QtObject floatingShape: null

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

    // Floating gap helper
    readonly property int floatingGap: floatingShape ? floatingShape.gap : Math.round(4 * sideBottomSurfaces.localScale)

    // Popup Views
    readonly property alias archMenuPopupView: archMenuPopupView
    readonly property alias audioPopupView: audioPopupView
    readonly property alias quickControlPopupView: quickControlPopupView
    readonly property alias wallpaperPopupView: wallpaperPopupView
    readonly property alias clipboardPopupView: clipboardPopupView

    Item {
        id: leftCenterNotchArea
        HoverHandler { id: leftCenterNotchHover }
        width: PrefsService.isFloating
            ? (SurfaceState.isLeftCenterExpanded ? (archMenuPopupView.popupWidth + Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale)) : 0)
            : surfaceShape.lcnDepth
        height: PrefsService.isFloating
            ? (SurfaceState.isLeftCenterExpanded ? (archMenuPopupView.popupHeight + Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale * 2)) : 0)
            : surfaceShape.lcnHeight
        anchors.left: parent.left
        anchors.leftMargin: PrefsService.isFloating ? sideBottomSurfaces.floatingGap : Math.round(Theme.borderWidth * sideBottomSurfaces.localScale)
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        Behavior on width  { enabled: PrefsService.isFloating; NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
        Behavior on height { enabled: PrefsService.isFloating; NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }

        ArchMenu {
            id: archMenuPopupView
            localScale: sideBottomSurfaces.localScale
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                radius: Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale)
                color: Theme.background
                visible: PrefsService.isFloating
                z: -1
            }

            opacity: SurfaceState.activeContent === "archMenu" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }
    }

    Item {
        id: rightCenterNotchArea
        HoverHandler { id: rightCenterNotchHover }
        width: PrefsService.isFloating
            ? (SurfaceState.isRightCenterExpanded ? (SurfaceState.activeContent === "audio" ? audioPopupView.popupWidth : (SurfaceState.activeContent === "quick" ? quickControlPopupView.popupWidth : Math.round(Theme.popupMaxWidth * sideBottomSurfaces.localScale))) : 0)
            : surfaceShape.rcnDepth
        height: PrefsService.isFloating
            ? (SurfaceState.isRightCenterExpanded ? (SurfaceState.activeContent === "audio" ? audioPopupView.popupHeight : (SurfaceState.activeContent === "quick" ? quickControlPopupView.popupHeight : Math.round(Theme.popupMaxHeight * sideBottomSurfaces.localScale))) : 0)
            : surfaceShape.rcnHeight
        anchors.right: parent.right
        anchors.rightMargin: PrefsService.isFloating ? sideBottomSurfaces.floatingGap : Math.round(Theme.borderWidth * sideBottomSurfaces.localScale)
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        Behavior on width  { enabled: PrefsService.isFloating; NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
        Behavior on height { enabled: PrefsService.isFloating; NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }

        AudioPopup {
            id: audioPopupView
            localScale: sideBottomSurfaces.localScale
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                radius: Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale)
                color: Theme.background
                visible: PrefsService.isFloating
                z: -1
            }

            opacity: SurfaceState.activeContent === "audio" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }

        QuickControl {
            id: quickControlPopupView
            localScale: sideBottomSurfaces.localScale
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                radius: Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale)
                color: Theme.background
                visible: PrefsService.isFloating
                z: -1
            }

            opacity: SurfaceState.activeContent === "quick" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }
    }

    Item {
        id: bottomCenterNotchArea
        HoverHandler { id: bottomCenterNotchHover }
        width: PrefsService.isFloating
            ? (SurfaceState.isBottomCenterExpanded ? (wallpaperPopupView.popupWidth + Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale * 2)) : 0)
            : surfaceShape.bcnWidth
        height: PrefsService.isFloating
            ? (SurfaceState.isBottomCenterExpanded ? (wallpaperPopupView.popupHeight + Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale)) : 0)
            : surfaceShape.bcnDepth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PrefsService.isFloating ? sideBottomSurfaces.floatingGap : Math.round(Theme.borderWidth * sideBottomSurfaces.localScale)
        clip: true
        Behavior on width  { enabled: PrefsService.isFloating; NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
        Behavior on height { enabled: PrefsService.isFloating; NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }

        WallpaperPopup {
            id: wallpaperPopupView
            localScale: sideBottomSurfaces.localScale
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                radius: Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale)
                color: Theme.background
                visible: PrefsService.isFloating
                z: -1
            }

            opacity: SurfaceState.activeContent === "wallpaper" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }
    }

    Item {
        id: bottomRightNotchArea
        HoverHandler { id: bottomRightNotchHover }
        width: PrefsService.isFloating
            ? (SurfaceState.isBottomRightExpanded ? (clipboardPopupView.popupWidth + Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale)) : 0)
            : surfaceShape.brnWidth
        height: PrefsService.isFloating
            ? (SurfaceState.isBottomRightExpanded ? (clipboardPopupView.popupHeight + Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale)) : 0)
            : surfaceShape.brnDepth
        anchors.right: parent.right
        anchors.rightMargin: PrefsService.isFloating ? sideBottomSurfaces.floatingGap : Math.round(Theme.borderWidth * sideBottomSurfaces.localScale)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PrefsService.isFloating ? sideBottomSurfaces.floatingGap : Math.round(Theme.borderWidth * sideBottomSurfaces.localScale)
        clip: true
        Behavior on width  { enabled: PrefsService.isFloating; NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
        Behavior on height { enabled: PrefsService.isFloating; NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }

        ClipboardPopup {
            id: clipboardPopupView
            localScale: sideBottomSurfaces.localScale
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                radius: Math.round(Theme.cornerRadius * sideBottomSurfaces.localScale)
                color: Theme.background
                visible: PrefsService.isFloating
                z: -1
            }

            opacity: SurfaceState.activeContent === "clipboard" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }
    }
}