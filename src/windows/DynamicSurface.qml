import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../theme"
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
        isRightHovered: rightNotchHover.hovered
        isLeftCenterHovered: leftCenterNotchHover.hovered
        isRightCenterHovered: rightCenterNotchHover.hovered
        isBottomCenterHovered: bottomCenterNotchHover.hovered
        isBottomRightHovered: bottomRightNotchHover.hovered
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

    // Mask logic: Combine frame borders + active notches + click shield. 
    mask: Region {
        Region { item: clickShield.isActive ? clickShield : null }
        
        // Top and Bottom frame borders
        Region { x: 0; y: 0; width: root.width; height: Math.max(1, surfaceShape.frameThickness) }
        Region { x: 0; y: root.height - Math.max(1, surfaceShape.frameThickness); width: root.width; height: Math.max(1, surfaceShape.frameThickness) }
        
        // Left and Right frame borders
        Region { x: 0; y: 0; width: Math.max(1, surfaceShape.frameThickness); height: root.height }
        Region { x: root.width - Math.max(1, surfaceShape.frameThickness); y: 0; width: Math.max(1, surfaceShape.frameThickness); height: root.height }
        
        // Top Notches
        Region { x: 0; y: 0; width: surfaceShape.leftNotchWidth; height: surfaceShape.leftNotchHeight }
        Region { x: root.width / 2 - surfaceShape.centerNotchWidth / 2; y: 0; width: surfaceShape.centerNotchWidth; height: surfaceShape.centerNotchHeight }
        Region { x: root.width - surfaceShape.rightNotchWidth; y: 0; width: surfaceShape.rightNotchWidth; height: surfaceShape.rightNotchHeight }
        
        // Side Notches
        Region { x: 0; y: root.height / 2 - (surfaceShape.lcnDepth > 1 ? surfaceShape.lcnHeight : Math.round(200 * root.localScale)) / 2; width: surfaceShape.lcnDepth > 1 ? surfaceShape.lcnDepth : Math.max(1, surfaceShape.frameThickness); height: surfaceShape.lcnDepth > 1 ? surfaceShape.lcnHeight : Math.round(200 * root.localScale) }
        Region { x: root.width - (surfaceShape.rcnDepth > 1 ? surfaceShape.rcnDepth : Math.max(1, surfaceShape.frameThickness)); y: root.height / 2 - (surfaceShape.rcnDepth > 1 ? surfaceShape.rcnHeight : Math.round(200 * root.localScale)) / 2; width: surfaceShape.rcnDepth > 1 ? surfaceShape.rcnDepth : Math.max(1, surfaceShape.frameThickness); height: surfaceShape.rcnDepth > 1 ? surfaceShape.rcnHeight : Math.round(200 * root.localScale) }
        
        // Bottom Notches
        Region { x: root.width / 2 - (surfaceShape.bcnDepth > 1 ? surfaceShape.bcnWidth : Math.round(300 * root.localScale)) / 2; y: root.height - (surfaceShape.bcnDepth > 1 ? surfaceShape.bcnDepth : Math.max(1, surfaceShape.frameThickness)); width: surfaceShape.bcnDepth > 1 ? surfaceShape.bcnWidth : Math.round(300 * root.localScale); height: surfaceShape.bcnDepth > 1 ? surfaceShape.bcnDepth : Math.max(1, surfaceShape.frameThickness) }
        Region { x: root.width - (surfaceShape.brnDepth > 1 ? surfaceShape.brnWidth : Math.round(200 * root.localScale)); y: root.height - (surfaceShape.brnDepth > 1 ? surfaceShape.brnDepth : Math.max(1, surfaceShape.frameThickness)); width: surfaceShape.brnDepth > 1 ? surfaceShape.brnWidth : Math.round(200 * root.localScale); height: surfaceShape.brnDepth > 1 ? surfaceShape.brnDepth : Math.max(1, surfaceShape.frameThickness) }
    }

    // --- VECTOR GEOMETRY ---
    // Focus Mode Independent Hitboxes
    Item {
        id: fmLeftTrigger
        anchors { left: parent.left; top: parent.top; leftMargin: Math.round(Theme.borderWidth * root.localScale) }
        width: Math.max(Math.round(Theme.lNotchMinWidth * localScale), Math.min(Math.round(Theme.lNotchMaxWidth * localScale), leftContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale)))
        height: Math.round(Theme.notchHeight * root.localScale)
        visible: ShellState.focusMode
        z: -1
        HoverHandler { id: fmLeftHov }
    }
    Item {
        id: fmCenterTrigger
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
        width: Math.max(Math.round(Theme.cNotchMinWidth * localScale), Math.min(Math.round(Theme.cNotchMaxWidth * localScale), centerContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale)))
        height: Math.round(Theme.notchHeight * root.localScale)
        visible: ShellState.focusMode
        z: -1
        HoverHandler { id: fmCenterHov; onHoveredChanged: Popups.dashboardTriggerHovered = hovered }
    }
    Item {
        id: fmRightTrigger
        anchors { right: parent.right; top: parent.top; rightMargin: Math.round(Theme.borderWidth * root.localScale) }
        width: Math.max(Math.round(Theme.rNotchMinWidth * localScale), Math.min(Math.round(Theme.rNotchMaxWidth * localScale), rightContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale)))
        height: Math.round(Theme.notchHeight * root.localScale)
        visible: ShellState.focusMode
        z: -1
        HoverHandler { id: fmRightHov }
    }

    SurfaceShape {
        id: surfaceShape
        anchors.fill: parent
        localScale: root.localScale
        
        rcnDepth: { 
            if (!SurfaceState.isRightCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "audio") return audioPopupView.popupWidth; 
            if (SurfaceState.activeContent === "quick") return quickControlPopupView.popupWidth; 
            return Math.round(Theme.popupMaxWidth * root.localScale); 
        } 
        rcnHeight: { 
            if (!SurfaceState.isRightCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "audio") return audioPopupView.popupHeight; 
            if (SurfaceState.activeContent === "quick") return quickControlPopupView.popupHeight; 
            return Math.round(Theme.popupMaxHeight * root.localScale); 
        }
        brnWidth: {
            if (!SurfaceState.isBottomRightExpanded) return innerRadius;
            if (SurfaceState.activeContent === "clipboard") return clipboardPopupView.popupWidth + Math.round(Theme.cornerRadius * root.localScale);
            return Math.round(Theme.popupMaxWidth * root.localScale);
        }
        lcnDepth: { 
            if (!SurfaceState.isLeftCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "archMenu") return archMenuPopupView.popupWidth + Math.round(Theme.cornerRadius * root.localScale); 
            return Math.round(Theme.popupMaxWidth * root.localScale); 
        } 
        lcnHeight: { 
            if (!SurfaceState.isLeftCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "archMenu") return archMenuPopupView.popupHeight + Math.round(Theme.cornerRadius * root.localScale * 2); 
            return Math.round(Theme.popupMaxHeight * root.localScale); 
        }
        bcnWidth: { 
            if (!SurfaceState.isBottomCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "wallpaper") return wallpaperPopupView.popupWidth + Math.round(Theme.cornerRadius * root.localScale * 2); 
            return Math.round(Theme.popupMaxWidth * root.localScale); 
        } 
        bcnDepth: { 
            if (!SurfaceState.isBottomCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "wallpaper") return wallpaperPopupView.popupHeight + Math.round(Theme.cornerRadius * root.localScale); 
            return Math.round(Theme.popupMaxHeight * root.localScale); 
        }
        brnDepth: {
            if (!SurfaceState.isBottomRightExpanded) return 0.001;
            if (SurfaceState.activeContent === "clipboard") return clipboardPopupView.popupHeight + Math.round(Theme.cornerRadius * root.localScale);
            return Math.round(Theme.popupMaxHeight * root.localScale);
        }
        
        leftNotchWidth: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (fmLeftHov.hovered || leftNotchHover.hovered))) ? 0.001 : Math.max(Math.round(Theme.lNotchMinWidth * localScale), Math.min(Math.round(Theme.lNotchMaxWidth * localScale), leftContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale)))
        leftNotchHeight: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (fmLeftHov.hovered || leftNotchHover.hovered))) ? surfaceShape.innerRadius : Math.round(Theme.notchHeight * root.localScale)
        centerNotchWidth: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (fmCenterHov.hovered || centerNotchHover.hovered)) && !SurfaceState.isTopExpanded && !ShellState.screenRecord && !ScreenRecService.recording && !Popups.miniPlayerOpen) ? 0.001 : (SurfaceState.isTopExpanded ? Math.round(Popups.dashboardPageWidth * root.localScale) : Math.max(Math.round(Theme.cNotchMinWidth * localScale), Math.min(Math.round(Theme.cNotchMaxWidth * localScale), centerContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale))))
        centerNotchHeight: {
            if (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (fmCenterHov.hovered || centerNotchHover.hovered)) && !SurfaceState.isTopExpanded && !ShellState.screenRecord && !ScreenRecService.recording && !Popups.miniPlayerOpen) return 0.001;
            if (SurfaceState.isTopExpanded) return Math.round(Theme.dashboardHeight * root.localScale);
            if (Popups.miniPlayerOpen) return Math.round(Theme.notchHeight * root.localScale) + miniPlayerView.height + Math.round(16 * root.localScale);
            if (ShellState.screenRecord && !ScreenRecService.recording && ScreenRecService.optionsExpanded) return Math.round(Theme.notchHeight * root.localScale) + screenRecOptionsPopupView.height + Math.round(16 * root.localScale);
            return Math.round(Theme.notchHeight * root.localScale);
        }
        rightNotchWidth: {
            if (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (fmRightHov.hovered || rightNotchHover.hovered)) && !SurfaceState.isRightExpanded && !Popups.notificationToastOpen) return 0.001;
            if (!SurfaceState.isRightExpanded) {
                if (Popups.notificationToastOpen) return notificationToastView.toastWidth + Math.round(Theme.cornerRadius * root.localScale);
                return Math.max(Math.round(Theme.rNotchMinWidth * localScale), Math.min(Math.round(Theme.rNotchMaxWidth * localScale), rightContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale)));
            }
            if (SurfaceState.activeContent === "network") return Math.round(Theme.networkPopupWidth * root.localScale) + Math.round(Theme.cornerRadius * root.localScale);
            if (SurfaceState.activeContent === "notifications") return notifsPopupView.popupWidth + Math.round(Theme.cornerRadius * root.localScale);
            return Math.round(Theme.popupMaxWidth * root.localScale);
        }
        rightNotchHeight: {
            if (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (fmRightHov.hovered || rightNotchHover.hovered)) && !SurfaceState.isRightExpanded && !Popups.notificationToastOpen) return surfaceShape.innerRadius;
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
    
    
    // --- NOTCH CONTENT ---
    Item {
        id: leftNotchArea
        HoverHandler { id: leftNotchHover }
        width: surfaceShape.leftNotchWidth
        height: surfaceShape.leftNotchHeight
        anchors.left: parent.left
        anchors.leftMargin: Math.round(Theme.borderWidth * root.localScale)
        anchors.top: parent.top
        anchors.topMargin: Math.round(Theme.borderWidth * root.localScale)
        clip: true
        
        opacity: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (fmLeftHov.hovered || leftNotchHover.hovered)) && !SurfaceState.isTopExpanded) ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        
        Item {
            id: leftNotchHead
            width: parent.width
            height: Math.round(Theme.notchHeight * root.localScale)
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
        width: surfaceShape.centerNotchWidth
        height: surfaceShape.centerNotchHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(Theme.borderWidth * root.localScale)
        clip: true
        
        opacity: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (fmCenterHov.hovered || centerNotchHover.hovered)) && !SurfaceState.isTopExpanded && !ShellState.screenRecord && !ScreenRecService.recording) ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        
        Item {
            id: centerNotchHead
            width: parent.width
            height: Math.round(Theme.notchHeight * root.localScale)
            anchors.top: parent.top
            
            CenterContent {
                localScale: root.localScale
                id: centerContent
                anchors.centerIn: parent
            }
        }

        Dashboard {
            id: dashboardView
            localScale: root.localScale
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            screen: root.screen
            
            opacity: SurfaceState.activeContent === "dashboard" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }
    ScreenRecOptionsPopup {
        id: screenRecOptionsPopupView
        localScale: root.localScale
        x: ScreenRecService.popupTargetX + (ScreenRecService.popupTargetWidth / 2) - (width / 2) - parent.x
        y: Math.round(8 * root.localScale) + Math.round(Theme.notchHeight * root.localScale)
        z: 999
    }
    MiniPlayer {
        id: miniPlayerView
        localScale: root.localScale
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(8 * root.localScale) + Math.round(Theme.notchHeight * root.localScale)
        z: 998
    }
    }


    Item {
        id: rightNotchArea
        HoverHandler { id: rightNotchHover }
        width: surfaceShape.rightNotchWidth
        height: surfaceShape.rightNotchHeight
        anchors.right: parent.right
        anchors.rightMargin: Math.round(Theme.borderWidth * root.localScale)
        anchors.top: parent.top
        anchors.topMargin: Math.round(Theme.borderWidth * root.localScale)
        clip: true
        
        opacity: (ShellState.focusMode && !(PrefsService.focusModeHoverExpand && (fmRightHov.hovered || rightNotchHover.hovered)) && !SurfaceState.isRightExpanded && !Popups.notificationToastOpen) ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        
        Item {
            id: rightNotchHead
            width: parent.width
            height: Math.round(Theme.notchHeight * root.localScale)
            anchors.top: parent.top
            
            RightContent {
                localScale: root.localScale
                id: rightContent
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Math.round(Theme.notchPadding * root.localScale)
            }
        }

        NetworkPopup {
            id: networkPopupView
            localScale: root.localScale
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            screen: root.screen
            
            opacity: SurfaceState.activeContent === "network" ? 1 : 0

            
            visible: opacity > 0

            
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }

        NotificationsPopup {
            id: notifsPopupView
            localScale: root.localScale
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            
            opacity: SurfaceState.activeContent === "notifications" ? 1 : 0

            
            visible: opacity > 0

            
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }

        NotificationToast {
            id: notificationToastView
            localScale: root.localScale
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            
            opacity: Popups.notificationToastOpen && !Popups.notificationsOpen ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }
    }

    Item {
        id: leftCenterNotchArea
        HoverHandler { id: leftCenterNotchHover }
        width: surfaceShape.lcnDepth
        height: surfaceShape.lcnHeight
        anchors.left: parent.left
        anchors.leftMargin: Math.round(Theme.borderWidth * root.localScale)
        anchors.verticalCenter: parent.verticalCenter

        ArchMenu {
            id: archMenuPopupView
            localScale: root.localScale
            anchors.fill: parent
            opacity: SurfaceState.activeContent === "archMenu" ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }
    }

    Item {
        id: rightCenterNotchArea
        HoverHandler { id: rightCenterNotchHover }
        width: surfaceShape.rcnDepth
        height: surfaceShape.rcnHeight
        anchors.right: parent.right
        anchors.rightMargin: Math.round(Theme.borderWidth * root.localScale)
        anchors.verticalCenter: parent.verticalCenter

        AudioPopup {
            id: audioPopupView
            localScale: root.localScale
            anchors.fill: parent
            opacity: SurfaceState.activeContent === "audio" ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }

        QuickControl {
            id: quickControlPopupView
            localScale: root.localScale
            anchors.fill: parent
            opacity: SurfaceState.activeContent === "quick" ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }
    }

    Item {
        id: bottomCenterNotchArea
        HoverHandler { id: bottomCenterNotchHover }
        width: surfaceShape.bcnWidth
        height: surfaceShape.bcnDepth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(Theme.borderWidth * root.localScale)

        WallpaperPopup {
            id: wallpaperPopupView
            localScale: root.localScale
            anchors.fill: parent
            opacity: SurfaceState.activeContent === "wallpaper" ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }
    }

    Item {
        id: bottomRightNotchArea
        HoverHandler { id: bottomRightNotchHover }
        width: surfaceShape.brnWidth
        height: surfaceShape.brnDepth
        anchors.right: parent.right
        anchors.rightMargin: Math.round(Theme.borderWidth * root.localScale)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(Theme.borderWidth * root.localScale)

        ClipboardPopup {
            id: clipboardPopupView
            localScale: root.localScale
            anchors.fill: parent
            opacity: SurfaceState.activeContent === "clipboard" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }
    }

}