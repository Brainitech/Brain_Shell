import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../theme"
import "../modules/Center/"
import "../modules/Right/"
import "../modules/Left/"
import "../popups/"

// A morphing Wayland window layer for the unified screen frame
PanelWindow {
    id: root
    property int leftContentWidth: leftContent.implicitWidth
    property int centerContentWidth: centerContent.implicitWidth
    property int rightContentWidth: rightContent.implicitWidth
    property var screen
    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    // Counteract the compositor's usable area squish (caused by our StrutWindows)
    // by pushing the bounds back out to the absolute screen edges.
    margins {
        top: Math.round(-40 * localScale) - Math.round(Theme.borderWidth * localScale) * 2
        bottom: -Math.round(Theme.borderWidth * localScale) * 2
        left: -Math.round(Theme.borderWidth * localScale) * 2
        right: -Math.round(Theme.borderWidth * localScale) * 2
    }
    
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "brain-shell-frame"
    WlrLayershell.keyboardFocus: (SurfaceState.activeSurface !== "none" || (ShellState.screenRecord && !ScreenRecService.recording)) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // --- CLICK SHIELD ---
    ClickShield { id: clickShield }

    // --- MASK PROXIES ---
    // These track the exact boundaries so clicks pass through to Hyprland when empty
    Item { id: topMask; width: parent.width; height: surfaceShape.frameThickness }
    Item { id: bottomMask; width: parent.width; height: surfaceShape.frameThickness; anchors.bottom: parent.bottom }
    Item { id: leftMask; width: surfaceShape.frameThickness; height: parent.height }
    Item { id: rightMask; width: surfaceShape.frameThickness; height: parent.height; anchors.right: parent.right }
    
    Item { 
        id: leftNotchMask
        width: surfaceShape.leftNotchWidth + (surfaceShape.flareRadius * 2)
        height: surfaceShape.leftNotchHeight + surfaceShape.flareRadius
        x: 0
    }
    Item { 
        id: centerNotchMask
        width: surfaceShape.centerNotchWidth + (surfaceShape.flareRadius * 2)
        height: surfaceShape.centerNotchHeight + surfaceShape.flareRadius
        anchors.horizontalCenter: parent.horizontalCenter
        TapHandler { 
            onTapped: SurfaceState.toggle("top", "dashboard") 
        }
    }
    Item { 
        id: rightNotchMask
        width: surfaceShape.rightNotchWidth + (surfaceShape.flareRadius * 2)
        height: surfaceShape.rightNotchHeight + surfaceShape.flareRadius
        anchors.right: parent.right
    }

    Item { 
        id: leftCenterNotchMask
        width: Math.max(100, surfaceShape.lcnDepth + (surfaceShape.flareRadius * 2))
        height: Math.max(200, surfaceShape.lcnHeight + (surfaceShape.flareRadius * 2))
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        TapHandler { 
            onTapped: SurfaceState.toggle("leftCenter", "archMenu") 
        }
        HoverHandler {
            onHoveredChanged: Popups.archMenuTriggerHovered = hovered
        }
    }
    Item { 
        id: rightCenterNotchMask
        width: Math.max(100, surfaceShape.rcnDepth + (surfaceShape.flareRadius * 2))
        height: Math.max(200, surfaceShape.rcnHeight + (surfaceShape.flareRadius * 2))
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        TapHandler { 
            onTapped: SurfaceState.toggle("rightCenter", "audio") 
        }
        HoverHandler {
            onHoveredChanged: {
                Popups.quickTriggerHovered = Popups.audioOpen ? false : hovered  
                Popups.audioTriggerHovered = hovered
            }
        }
    }
    Item { 
        id: bottomCenterNotchMask
        width: Math.max(300, surfaceShape.bcnWidth + (surfaceShape.flareRadius * 2))
        height: Math.max(100, surfaceShape.bcnDepth + (surfaceShape.flareRadius * 2))
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        TapHandler { 
            onTapped: SurfaceState.toggle("bottomCenter", "wallpaper") 
        }
        HoverHandler {
            onHoveredChanged: Popups.wallpaperTriggerHovered = hovered
        }
    }
    Item { 
        id: bottomRightNotchMask
        width: Math.max(200, surfaceShape.brnWidth + (surfaceShape.flareRadius * 2))
        height: Math.max(100, surfaceShape.brnDepth + (surfaceShape.flareRadius * 2))
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        TapHandler { 
            onTapped: SurfaceState.toggle("bottomRight", "clipboard") 
        }
        HoverHandler {
            onHoveredChanged: Popups.clipboardTriggerHovered = hovered
        }
    }

    Region {
        id: frameRegion
        Region { item: topMask }
        Region { item: bottomMask }
        Region { item: leftMask }
        Region { item: rightMask }
        
        // Top Notches (Always visible base)
        Region {
            x: 0; y: 0
            width: surfaceShape.leftNotchWidth + (surfaceShape.flareRadius * 2)
            height: surfaceShape.leftNotchHeight + surfaceShape.flareRadius
        }
        Region {
            x: root.width / 2 - (surfaceShape.centerNotchWidth / 2) - surfaceShape.flareRadius; y: 0
            width: surfaceShape.centerNotchWidth + (surfaceShape.flareRadius * 2)
            height: surfaceShape.centerNotchHeight + surfaceShape.flareRadius
        }
        Region {
            x: root.width - surfaceShape.rightNotchWidth - (surfaceShape.flareRadius * 2); y: 0
            width: surfaceShape.rightNotchWidth + (surfaceShape.flareRadius * 2)
            height: surfaceShape.rightNotchHeight + surfaceShape.flareRadius
        }
        
        // Dynamic Side/Bottom Notches (Hidden when closed via > 1 check to avoid blurring edge artifacts)
        Region {
            x: 0; y: root.height / 2 - (surfaceShape.lcnHeight / 2) - surfaceShape.flareRadius
            width: surfaceShape.lcnDepth > 1 ? surfaceShape.lcnDepth + (surfaceShape.flareRadius * 2) : 0
            height: surfaceShape.lcnDepth > 1 ? surfaceShape.lcnHeight + (surfaceShape.flareRadius * 2) : 0
        }
        Region {
            x: root.width - surfaceShape.rcnDepth - (surfaceShape.flareRadius * 2); y: root.height / 2 - (surfaceShape.rcnHeight / 2) - surfaceShape.flareRadius
            width: surfaceShape.rcnDepth > 1 ? surfaceShape.rcnDepth + (surfaceShape.flareRadius * 2) : 0
            height: surfaceShape.rcnDepth > 1 ? surfaceShape.rcnHeight + (surfaceShape.flareRadius * 2) : 0
        }
        Region {
            x: root.width / 2 - (surfaceShape.bcnWidth / 2) - surfaceShape.flareRadius; y: root.height - surfaceShape.bcnDepth - (surfaceShape.flareRadius * 2)
            width: surfaceShape.bcnDepth > 1 ? surfaceShape.bcnWidth + (surfaceShape.flareRadius * 2) : 0
            height: surfaceShape.bcnDepth > 1 ? surfaceShape.bcnDepth + (surfaceShape.flareRadius * 2) : 0
        }
        Region {
            x: root.width - surfaceShape.brnWidth - (surfaceShape.flareRadius * 2); y: root.height - surfaceShape.brnDepth - (surfaceShape.flareRadius * 2)
            width: surfaceShape.brnDepth > 1 ? surfaceShape.brnWidth + (surfaceShape.flareRadius * 2) : 0
            height: surfaceShape.brnDepth > 1 ? surfaceShape.brnDepth + (surfaceShape.flareRadius * 2) : 0
        }
    }

    BackgroundEffect.blurRegion: PrefsService.bgBlur ? frameRegion : null

    // Mask logic: Combine frame borders + active notches + click shield. 
    mask: Region { 
        Region { item: clickShield.isActive ? clickShield : null }
        Region { item: topMask }
        Region { item: bottomMask }
        Region { item: leftMask }
        Region { item: rightMask }
        Region { item: leftNotchMask }
        Region { item: centerNotchMask }
        Region { item: rightNotchMask }
        Region { item: leftCenterNotchMask }
        Region { item: rightCenterNotchMask }
        Region { item: bottomCenterNotchMask }
        Region { item: bottomRightNotchMask }
    }

    // --- VECTOR GEOMETRY ---
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
            if (SurfaceState.activeContent === "clipboard") return clipboardPopupView.popupWidth + Math.round(Theme.notchRadius * root.localScale);
            return Math.round(Theme.popupMaxWidth * root.localScale);
        }
        lcnDepth: { 
            if (!SurfaceState.isLeftCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "archMenu") return archMenuPopupView.popupWidth + Math.round(Theme.notchRadius * root.localScale); 
            return Math.round(Theme.popupMaxWidth * root.localScale); 
        } 
        lcnHeight: { 
            if (!SurfaceState.isLeftCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "archMenu") return archMenuPopupView.popupHeight + Math.round(Theme.notchRadius * root.localScale * 2); 
            return Math.round(Theme.popupMaxHeight * root.localScale); 
        }
        bcnWidth: { 
            if (!SurfaceState.isBottomCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "wallpaper") return wallpaperPopupView.popupWidth + Math.round(Theme.notchRadius * root.localScale * 2); 
            return Math.round(Theme.popupMaxWidth * root.localScale); 
        } 
        bcnDepth: { 
            if (!SurfaceState.isBottomCenterExpanded) return 0.001; 
            if (SurfaceState.activeContent === "wallpaper") return wallpaperPopupView.popupHeight + Math.round(Theme.notchRadius * root.localScale); 
            return Math.round(Theme.popupMaxHeight * root.localScale); 
        }
        brnDepth: {
            if (!SurfaceState.isBottomRightExpanded) return 0.001;
            if (SurfaceState.activeContent === "clipboard") return clipboardPopupView.popupHeight + Math.round(Theme.notchRadius * root.localScale);
            return Math.round(Theme.popupMaxHeight * root.localScale);
        }
        
        leftNotchWidth: SurfaceState.isLeftExpanded ? Math.round(Theme.popupMaxWidth * root.localScale) : Math.max(Math.round(Theme.lNotchMinWidth * localScale), Math.min(Math.round(Theme.lNotchMaxWidth * localScale), leftContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale)))
        centerNotchWidth: SurfaceState.isTopExpanded ? Math.round(Popups.dashboardPageWidth * root.localScale) : Math.max(Math.round(Theme.cNotchMinWidth * localScale), Math.min(Math.round(Theme.cNotchMaxWidth * localScale), centerContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale)))
        centerNotchHeight: {
            if (SurfaceState.isTopExpanded) return Math.round(Theme.dashboardHeight * root.localScale);
            if (ScreenRecService.openStrip !== "") return Math.round(Theme.notchHeight * root.localScale) + screenRecOptionsPopupView.height + Math.round(16 * root.localScale);
            return Math.round(Theme.notchHeight * root.localScale);
        }
        rightNotchWidth: {
            if (!SurfaceState.isRightExpanded) {
                if (Popups.notificationToastOpen) return notificationToastView.toastWidth + Math.round(Theme.notchRadius * root.localScale);
                return Math.max(Math.round(Theme.rNotchMinWidth * localScale), Math.min(Math.round(Theme.rNotchMaxWidth * localScale), rightContent.implicitWidth + Math.round(Theme.notchPadding * 2 * localScale)));
            }
            if (SurfaceState.activeContent === "network") return Math.round(Theme.networkPopupWidth * root.localScale) + Math.round(Theme.notchRadius * root.localScale);
            if (SurfaceState.activeContent === "notifications") return notifsPopupView.popupWidth + Math.round(Theme.notchRadius * root.localScale);
            return Math.round(Theme.popupMaxWidth * root.localScale);
        }
        rightNotchHeight: {
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
        width: surfaceShape.leftNotchWidth
        height: surfaceShape.leftNotchHeight
        anchors.left: parent.left
        anchors.leftMargin: Math.round(Theme.borderWidth * root.localScale)
        anchors.top: parent.top
        
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
        width: surfaceShape.centerNotchWidth
        height: surfaceShape.centerNotchHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        
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
            
            opacity: Popups.dashboardOpen ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }
    }

    Item {
        id: rightNotchArea
        width: surfaceShape.rightNotchWidth
        height: surfaceShape.rightNotchHeight
        anchors.right: parent.right
        anchors.rightMargin: Math.round(Theme.borderWidth * root.localScale)
        anchors.top: parent.top
        clip: true
        
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
            
            opacity: Popups.networkOpen ? 1 : 0

            
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
            
            opacity: Popups.notificationsOpen ? 1 : 0

            
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
        width: surfaceShape.lcnDepth
        height: surfaceShape.lcnHeight
        anchors.left: parent.left
        anchors.leftMargin: Math.round(Theme.borderWidth * root.localScale)
        anchors.verticalCenter: parent.verticalCenter

        ArchMenu {
            id: archMenuPopupView
            localScale: root.localScale
            anchors.fill: parent
            opacity: Popups.archMenuOpen ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }
    }

    Item {
        id: rightCenterNotchArea
        width: surfaceShape.rcnDepth
        height: surfaceShape.rcnHeight
        anchors.right: parent.right
        anchors.rightMargin: Math.round(Theme.borderWidth * root.localScale)
        anchors.verticalCenter: parent.verticalCenter

        AudioPopup {
            id: audioPopupView
            localScale: root.localScale
            anchors.fill: parent
            opacity: Popups.audioOpen ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }

        QuickControl {
            id: quickControlPopupView
            localScale: root.localScale
            anchors.fill: parent
            opacity: Popups.quickOpen ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }
    }

    Item {
        id: bottomCenterNotchArea
        width: surfaceShape.bcnWidth
        height: surfaceShape.bcnDepth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(Theme.borderWidth * root.localScale)

        WallpaperPopup {
            id: wallpaperPopupView
            localScale: root.localScale
            anchors.fill: parent
            opacity: Popups.wallpaperOpen ? 1 : 0

            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
        }
    }

    Item {
        id: bottomRightNotchArea
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
        }
    }

    ScreenRecOptionsPopup {
        id: screenRecOptionsPopupView
        localScale: root.localScale
        x: ScreenRecService.popupTargetX + (ScreenRecService.popupTargetWidth / 2) - (width / 2)
        y: Math.round(25 * root.localScale) + Math.round(Theme.notchHeight * root.localScale)
        z: 999
    }

    // --- GLOBAL ESCAPE HANDLER ---
    Item {
        anchors.fill: parent
        focus: SurfaceState.activeSurface !== "none" || (ShellState.screenRecord && !ScreenRecService.recording)

        Keys.onEscapePressed: {
            SurfaceState.close()
            ScreenRecService.cancelSetup()
        }
    }

    // --- HYPRLAND EVENT DISMISS ---
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "activemonitor" || event.name === "activespecial" || event.name === "openwindow") {
                SurfaceState.close()
            }
        }
    }
}
// Will be modularized once everything works
