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
import Quickshell
import Quickshell.Wayland

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

    property Item leftCenterArea: null
    property Item rightCenterArea: null
    property Item bottomCenterArea: null
    property Item bottomRightArea: null

    focus: SurfaceState.activeSurface !== "none" || (screenRecord && !screenRecording)

    // --- INPUT & EVENT SHIELDING ---
    readonly property bool hasActiveTextInput: parent && parent.activeFocusItem !== null && parent.activeFocusItem !== undefined && typeof parent.activeFocusItem.cursorPosition === "number"
    readonly property bool isInputActive: Popups.isInputActive || hasActiveTextInput

    function pinActiveSurface() {
        if (SurfaceState.activeContent === "dashboard") Popups.dashboardPinned = true;
        else if (SurfaceState.activeContent === "wallpaper") Popups.wallpaperPinned = true;
        else if (SurfaceState.activeContent === "network") Popups.networkPinned = true;
        else if (SurfaceState.activeContent === "archMenu") Popups.archMenuPinned = true;
        else if (SurfaceState.activeContent === "clipboard") Popups.clipboardPinned = true;
        else if (SurfaceState.activeContent === "audio") Popups.audioPinned = true;
        else if (SurfaceState.activeContent === "quick") Popups.quickPinned = true;
        else if (SurfaceState.activeContent === "notifications") Popups.notificationsPinned = true;
    }

    onIsInputActiveChanged: {
        if (isInputActive) {
            pinActiveSurface()
        }
    }

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
            if (inputManager.isInputActive) return;
            if (Date.now() - SurfaceState.lastCloseTime < 400) return;
            if (Popups.dashboardTriggerHovered && Popups.dashboardAllowHover) {
                if (SurfaceState.activeSurface !== "top" || SurfaceState.activeContent !== "dashboard") {
                    Popups.closeAll()
                    SurfaceState.open("top", "dashboard")
                }
            }
            else if (Popups.archMenuTriggerHovered && Popups.archMenuAllowHover) {
                if (SurfaceState.activeSurface !== "leftCenter" || SurfaceState.activeContent !== "archMenu") {
                    Popups.closeAll()
                    SurfaceState.open("leftCenter", "archMenu")
                }
            }
            else if (Popups.audioTriggerHovered && Popups.audioAllowHover) {
                if (SurfaceState.activeSurface !== "rightCenter" || SurfaceState.activeContent !== "audio") {
                    Popups.closeAll()
                    SurfaceState.open("rightCenter", "audio")
                }
            }
            else if (Popups.networkTriggerHovered && Popups.networkAllowHover) {
                if (SurfaceState.activeSurface !== "right" || SurfaceState.activeContent !== "network") {
                    Popups.closeAll()
                    SurfaceState.open("right", "network")
                }
            } 
            else if (Popups.notificationsTriggerHovered && Popups.notificationsAllowHover) {
                if (SurfaceState.activeSurface !== "right" || SurfaceState.activeContent !== "notifications") {
                    Popups.closeAll()
                    SurfaceState.open("right", "notifications")
                }
            }
            else if (Popups.wallpaperTriggerHovered && Popups.wallpaperAllowHover) {
                if (SurfaceState.activeSurface !== "bottomCenter" || SurfaceState.activeContent !== "wallpaper") {
                    Popups.closeAll()
                    SurfaceState.open("bottomCenter", "wallpaper")
                }
            }
            else if (Popups.quickTriggerHovered && Popups.quickAllowHover) {
                if (SurfaceState.activeSurface !== "rightCenter" || SurfaceState.activeContent !== "quick") {
                    Popups.closeAll()
                    SurfaceState.open("rightCenter", "quick")
                }
            }
            else if (Popups.clipboardTriggerHovered && Popups.clipboardAllowHover) {
                if (SurfaceState.activeSurface !== "bottomRight" || SurfaceState.activeContent !== "clipboard") {
                    Popups.closeAll()
                    SurfaceState.open("bottomRight", "clipboard")
                }
            }
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: Popups.hoverCloseDelay
        onTriggered: {
            if (inputManager.isInputActive) return;
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
        width: SurfaceState.isLeftCenterExpanded 
            ? Math.max(
                (PrefsService.isFloating ? 1 : Math.max(1, surfaceShape.frameThickness)),
                ((leftCenterArea ? leftCenterArea.width : Math.round(Theme.popupMaxWidth * inputManager.localScale)) + (PrefsService.isFloating ? Math.max(4, PrefsService.floatingGap) : 0))
              )
            : (surfaceShape.lcnDepth > 1 ? surfaceShape.lcnDepth : (PrefsService.isFloating ? 1 : Math.max(1, surfaceShape.frameThickness)))
        height: SurfaceState.isLeftCenterExpanded 
            ? Math.max(
                Math.round(200 * inputManager.localScale),
                (leftCenterArea ? leftCenterArea.height : Math.round(Theme.popupMaxHeight * inputManager.localScale))
              )
            : (surfaceShape.lcnDepth > 1 ? surfaceShape.lcnHeight : Math.round(200 * inputManager.localScale))
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        visible: true
        MouseArea { 
            anchors.fill: parent
            onClicked: {
                if (SurfaceState.activeContent === "archMenu" && Popups.archMenuAllowHover) {
                    Popups.archMenuPinned = !Popups.archMenuPinned
                    return
                }
                if (!Popups.archMenuAllowHover) {
                    var next = (SurfaceState.activeContent !== "archMenu")
                    SurfaceState.toggle("leftCenter", "archMenu")
                    if (next) Popups.archMenuPinned = true
                }
            }
        }
        HoverHandler {
            onHoveredChanged: Popups.archMenuTriggerHovered = hovered
        }
    }
    Item { 
        id: rightCenterNotchMask
        width: SurfaceState.isRightCenterExpanded 
            ? Math.max(
                (PrefsService.isFloating ? 1 : Math.max(1, surfaceShape.frameThickness)),
                ((rightCenterArea ? rightCenterArea.width : Math.round(Theme.popupMaxWidth * inputManager.localScale)) + (PrefsService.isFloating ? Math.max(4, PrefsService.floatingGap) : 0))
              )
            : (surfaceShape.rcnDepth > 1 ? surfaceShape.rcnDepth : (PrefsService.isFloating ? 1 : Math.max(1, surfaceShape.frameThickness)))
        height: SurfaceState.isRightCenterExpanded 
            ? Math.max(
                Math.round(200 * inputManager.localScale),
                (rightCenterArea ? rightCenterArea.height : Math.round(Theme.popupMaxHeight * inputManager.localScale))
              )
            : (surfaceShape.rcnDepth > 1 ? surfaceShape.rcnHeight : Math.round(200 * inputManager.localScale))
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: true
        MouseArea { 
            anchors.fill: parent
            onClicked: {
                if (Popups.audioOpen && Popups.audioAllowHover) {
                    Popups.audioPinned = !Popups.audioPinned
                    return
                }
                if (SurfaceState.activeContent === "quick" && Popups.quickAllowHover) {
                    Popups.quickPinned = !Popups.quickPinned
                    return
                }
                if (!Popups.audioAllowHover && !Popups.quickAllowHover) {
                    if (Popups.audioOpen) {
                        SurfaceState.toggle("rightCenter", "audio")
                    } else if (SurfaceState.activeContent === "quick") {
                        SurfaceState.toggle("rightCenter", "quick")
                    } else {
                        SurfaceState.toggle("rightCenter", "quick")
                        Popups.quickPinned = true
                    }
                }
            }
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
                Popups.quickTriggerHovered = Popups.audioOpen ? false : inputManager.isRightCenterHovered
            }
        }
    }
    Item { 
        id: bottomCenterNotchMask
        width: SurfaceState.isBottomCenterExpanded 
            ? Math.max(
                Math.round(300 * inputManager.localScale),
                (bottomCenterArea ? bottomCenterArea.width : Math.round(Theme.popupMaxWidth * inputManager.localScale))
              )
            : (surfaceShape.bcnDepth > 1 ? surfaceShape.bcnWidth : Math.round(300 * inputManager.localScale))
        height: SurfaceState.isBottomCenterExpanded 
            ? Math.max(
                (PrefsService.isFloating ? 1 : Math.max(1, surfaceShape.frameThickness)),
                ((bottomCenterArea ? bottomCenterArea.height : Math.round(Theme.popupMaxHeight * inputManager.localScale)) + (PrefsService.isFloating ? Math.max(4, PrefsService.floatingGap) : 0))
              )
            : (surfaceShape.bcnDepth > 1 ? surfaceShape.bcnDepth : (PrefsService.isFloating ? 1 : Math.max(1, surfaceShape.frameThickness)))
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        visible: true
        MouseArea { 
            anchors.fill: parent
            onClicked: {
                if (SurfaceState.activeContent === "wallpaper" && Popups.wallpaperAllowHover) {
                    Popups.wallpaperPinned = !Popups.wallpaperPinned
                    return
                }
                if (!Popups.wallpaperAllowHover) {
                    var next = (SurfaceState.activeContent !== "wallpaper")
                    SurfaceState.toggle("bottomCenter", "wallpaper")
                    if (next) Popups.wallpaperPinned = true
                }
            }
        }
        HoverHandler {
            onHoveredChanged: Popups.wallpaperTriggerHovered = hovered
        }
    }
    Item { 
        id: bottomRightNotchMask
        width: SurfaceState.isBottomRightExpanded 
            ? Math.max(
                Math.round(200 * inputManager.localScale),
                ((bottomRightArea ? bottomRightArea.width : Math.round(Theme.popupMaxWidth * inputManager.localScale)) + (PrefsService.isFloating ? Math.max(4, PrefsService.floatingGap) : 0))
              )
            : (surfaceShape.brnDepth > 1 ? surfaceShape.brnWidth : Math.round(200 * inputManager.localScale))
        height: SurfaceState.isBottomRightExpanded 
            ? Math.max(
                (PrefsService.isFloating ? 1 : Math.max(1, surfaceShape.frameThickness)),
                ((bottomRightArea ? bottomRightArea.height : Math.round(Theme.popupMaxHeight * inputManager.localScale)) + (PrefsService.isFloating ? Math.max(4, PrefsService.floatingGap) : 0))
              )
            : (surfaceShape.brnDepth > 1 ? surfaceShape.brnDepth : (PrefsService.isFloating ? 1 : Math.max(1, surfaceShape.frameThickness)))
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        visible: true
        MouseArea { 
            anchors.fill: parent
            onClicked: {
                if (SurfaceState.activeContent === "clipboard" && Popups.clipboardAllowHover) {
                    Popups.clipboardPinned = !Popups.clipboardPinned
                    return
                }
                if (!Popups.clipboardAllowHover) {
                    var next = (SurfaceState.activeContent !== "clipboard")
                    SurfaceState.toggle("bottomRight", "clipboard")
                    if (next) Popups.clipboardPinned = true
                }
            }
        }
        HoverHandler {
            onHoveredChanged: Popups.clipboardTriggerHovered = hovered
        }
    }

    // --- GLOBAL ESCAPE HANDLER ---
    Keys.onEscapePressed: {
        if (Popups.miniPlayerOpen) {
            Popups.miniPlayerOpen = false
            return
        }
        if (inputManager.optionsExpanded) {
            ScreenRecService.optionsExpanded = false
        } else if (inputManager.screenRecord && !inputManager.screenRecording) {
            ScreenRecService.cancelSetup()
        }
        SurfaceState.close()
    }

    // --- WM EVENT DISMISS ---
    Connections {
        target: WM
        function onDismissRequested() {
            if (inputManager.isInputActive) return;
            Popups.miniPlayerOpen = false
            SurfaceState.close()
        }
    }
}