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
        isTopHovered: leftNotchHover.hovered || centerNotchHover.hovered || rightNotchHover.hovered
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

    // Pass the entire window bounding box to the compositor.
    BackgroundEffect.blurRegion: PrefsService.bgBlur ? fullRegion : null

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
        anchors.topMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
        width: PrefsService.isFloating ? floatingShape.centerPillWidth : surfaceShape.centerNotchWidth
        height: PrefsService.isFloating ? floatingShape.centerPillHeight : surfaceShape.centerNotchHeight
        clip: true
        visible: SurfaceState.isTopExpanded || dashboardView.opacity > 0

        Dashboard {
            id: dashboardView
            localScale: root.localScale
            anchors.fill: parent
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
        anchors.rightMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
        anchors.top: parent.top
        anchors.topMargin: PrefsService.isFloating ? floatingShape.gap : Math.round(Theme.borderWidth * root.localScale)
        width: PrefsService.isFloating ? floatingShape.rightPillWidth : surfaceShape.rightNotchWidth
        height: PrefsService.isFloating ? floatingShape.rightPillHeight : surfaceShape.rightNotchHeight
        clip: true
        visible: SurfaceState.isRightExpanded || Popups.notificationToastOpen || networkPopupView.opacity > 0 || notifsPopupView.opacity > 0 || notificationToastView.opacity > 0

        NetworkPopup {
            id: networkPopupView
            localScale: root.localScale
            anchors.fill: parent
            screen: root.screen

            opacity: SurfaceState.activeContent === "network" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }

        NotificationsPopup {
            id: notifsPopupView
            localScale: root.localScale
            anchors.fill: parent

            opacity: SurfaceState.activeContent === "notifications" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }
        }

        NotificationToast {
            id: notificationToastView
            localScale: root.localScale
            anchors.fill: parent

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