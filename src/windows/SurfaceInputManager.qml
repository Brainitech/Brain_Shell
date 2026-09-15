import QtQuick
import "../"
import "../theme"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: inputManager

    required property real localScale
    required property QtObject surfaceShape
    required property Item clickShield
    required property bool screenRecord
    required property bool screenRecording
    required property bool optionsExpanded


    required property bool isTopHovered
    required property bool isRightHovered
    required property bool isLeftCenterHovered
    required property bool isRightCenterHovered
    required property bool isBottomCenterHovered
    required property bool isBottomRightHovered
    focus: SurfaceState.activeSurface !== "none" || (screenRecord && !screenRecording)

    // --- GLOBAL HOVER MANAGER ---
    property bool _anyTriggerHovered: Popups.dashboardTriggerHovered || Popups.archMenuTriggerHovered || Popups.audioTriggerHovered || Popups.networkTriggerHovered || Popups.notificationsTriggerHovered || Popups.wallpaperTriggerHovered || Popups.quickTriggerHovered || Popups.clipboardTriggerHovered
    
    property bool _activeSurfaceHovered: {
        if (SurfaceState.activeSurface === "top") return isTopHovered;
        if (SurfaceState.activeSurface === "leftCenter") return isLeftCenterHovered;
        if (SurfaceState.activeSurface === "right") return isRightHovered;
        if (SurfaceState.activeSurface === "rightCenter") return isRightCenterHovered;
        if (SurfaceState.activeSurface === "bottomCenter") return isBottomCenterHovered;
        if (SurfaceState.activeSurface === "bottomRight") return isBottomRightHovered;
        return false;
    }

    on_AnyTriggerHoveredChanged: {
        if (_anyTriggerHovered) {
            hoverCloseTimer.stop()
            hoverOpenTimer.restart()
        } else {
            hoverOpenTimer.stop()
            if (!_activeSurfaceHovered) hoverCloseTimer.restart()
        }
    }

    on_ActiveSurfaceHoveredChanged: {
        if (!_anyTriggerHovered && !_activeSurfaceHovered) {
            hoverCloseTimer.restart()
        } else {
            hoverCloseTimer.stop()
        }
    }

    Timer {
        id: hoverOpenTimer
        interval: Popups.hoverOpenDelay
        onTriggered: {
            if (Popups.dashboardTriggerHovered && Popups.dashboardAllowHover) { Popups.closeAll(); SurfaceState.open("top", "dashboard") }
            else if (Popups.archMenuTriggerHovered && Popups.archMenuAllowHover) { Popups.closeAll(); SurfaceState.open("leftCenter", "archMenu") }
            else if (Popups.audioTriggerHovered && Popups.audioAllowHover) { Popups.closeAll(); SurfaceState.open("rightCenter", "audio") }
            else if (Popups.networkTriggerHovered && Popups.networkAllowHover) { Popups.closeAll(); SurfaceState.open("right", "network") } 
            else if (Popups.notificationsTriggerHovered && Popups.notificationsAllowHover) { Popups.closeAll(); SurfaceState.open("right", "notifications") }
            else if (Popups.wallpaperTriggerHovered && Popups.wallpaperAllowHover) { Popups.closeAll(); SurfaceState.open("bottomCenter", "wallpaper") }
            else if (Popups.quickTriggerHovered && Popups.quickAllowHover) { Popups.closeAll(); SurfaceState.open("rightCenter", "quick") }
            else if (Popups.clipboardTriggerHovered && Popups.clipboardAllowHover) { Popups.closeAll(); SurfaceState.open("bottomRight", "clipboard") }
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: Popups.hoverCloseDelay
        onTriggered: {
            if (!_anyTriggerHovered && !_activeSurfaceHovered && !Popups.colorPickerActive) {
                if (SurfaceState.activeContent === "dashboard" && Popups.dashboardPinned) return;
                if (SurfaceState.activeContent === "archMenu" && Popups.archMenuPinned) return;
                if (SurfaceState.activeContent === "audio" && Popups.audioPinned) return;
                if (SurfaceState.activeContent === "network" && Popups.networkPinned) return;
                if (SurfaceState.activeContent === "notifications" && Popups.notificationsPinned) return;
                if (SurfaceState.activeContent === "wallpaper" && Popups.wallpaperPinned) return;
                if (SurfaceState.activeContent === "quick" && Popups.quickPinned) return;
                if (SurfaceState.activeContent === "clipboard" && Popups.clipboardPinned) return;
                SurfaceState.close();
            }
        }
    }

    // --- MASK PROXIES ---
    
    Item { 
        id: leftCenterNotchMask
        width: surfaceShape.lcnDepth > 1 ? surfaceShape.lcnDepth : surfaceShape.frameThickness
        height: surfaceShape.lcnDepth > 1 ? surfaceShape.lcnHeight : Math.round(200 * inputManager.localScale)
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        MouseArea { 
            onClicked: {}
        }
        HoverHandler {
            onHoveredChanged: Popups.archMenuTriggerHovered = hovered
        }
    }
    Item { 
        id: rightCenterNotchMask
        width: surfaceShape.rcnDepth > 1 ? surfaceShape.rcnDepth : surfaceShape.frameThickness
        height: surfaceShape.rcnDepth > 1 ? surfaceShape.rcnHeight : Math.round(200 * inputManager.localScale)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        MouseArea { 
            onClicked: {}
        }
        HoverHandler {
            onHoveredChanged: {
                Popups.quickTriggerHovered = Popups.audioOpen ? false : hovered  
                Popups.audioTriggerHovered = hovered
            }
        }
        Connections {
            target: Popups
            function onAudioOpenChanged() {
                Popups.quickTriggerHovered = Popups.audioOpen ? false : rightCenterNotchHover.hovered
            }
        }
    }
    Item { 
        id: bottomCenterNotchMask
        width: surfaceShape.bcnDepth > 1 ? surfaceShape.bcnWidth : Math.round(300 * inputManager.localScale)
        height: surfaceShape.bcnDepth > 1 ? surfaceShape.bcnDepth : surfaceShape.frameThickness
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
        width: surfaceShape.brnDepth > 1 ? surfaceShape.brnWidth : Math.round(200 * inputManager.localScale)
        height: surfaceShape.brnDepth > 1 ? surfaceShape.brnDepth : surfaceShape.frameThickness
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        TapHandler { 
            onTapped: SurfaceState.toggle("bottomRight", "clipboard") 
        }
        HoverHandler {
            onHoveredChanged: Popups.clipboardTriggerHovered = hovered
        }
    }


    // --- GLOBAL ESCAPE HANDLER ---
    Keys.onEscapePressed: {
        if (inputManager.optionsExpanded) {
            ScreenRecService.optionsExpanded = false
        } else if (inputManager.screenRecord && !inputManager.screenRecording) {
            ScreenRecService.cancelSetup()
        }
        SurfaceState.close()
    }

    // --- HYPRLAND EVENT DISMISS ---
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "activemonitor" || event.name === "activespecial" || event.name === "openwindow") {
                if (SurfaceState.activeContent === "dashboard" && Popups.dashboardPage === "kanban" && Popups.tasksInteractionActive) return;
                SurfaceState.close()
            }
        }
    }
}
