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

Item {
    id: focusTriggers

    required property real localScale
    property Item leftContent: null
    property Item centerContent: null
    property Item rightContent: null
    property real leftContentImplicitWidth: leftContent ? leftContent.implicitWidth : 0
    property real centerContentImplicitWidth: centerContent ? centerContent.implicitWidth : 0
    property real rightContentImplicitWidth: rightContent ? rightContent.implicitWidth : 0

    // Trigger items
    readonly property alias topCenterTapTrigger: fmCenterTrigger
    readonly property alias fmLeftTrigger: fmLeftTrigger
    readonly property alias fmCenterTrigger: fmCenterTrigger
    readonly property alias fmRightTrigger: fmRightTrigger

    readonly property int idleTriggerHeight: PrefsService.isFloating
        ? Math.max(2, Math.round(2 * focusTriggers.localScale))
        : Math.max(2, Math.round(Theme.borderWidth * focusTriggers.localScale))

    readonly property int activeTriggerHeight: PrefsService.isFloating
        ? Math.round((Math.max(4, PrefsService.floatingGap) + PrefsService.floatingBarHeight) * focusTriggers.localScale)
        : Math.round(Theme.notchHeight * focusTriggers.localScale)

    readonly property int triggerHeight: activeTriggerHeight

    // Hover handlers
    readonly property alias fmLeftHov: fmLeftHov
    readonly property alias fmCenterHov: fmCenterHov
    readonly property alias fmRightHov: fmRightHov

    // Hover booleans
    readonly property alias fmLeftHovered: fmLeftHov.hovered
    readonly property alias fmCenterHovered: fmCenterHov.hovered
    readonly property alias fmRightHovered: fmRightHov.hovered

    // --- VECTOR GEOMETRY ---
    // Focus Mode & Edge Hitboxes
    Item {
        id: fmLeftTrigger
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: PrefsService.isFloating ? Math.max(4, Math.round(PrefsService.floatingGap * focusTriggers.localScale)) : Math.round(Theme.borderWidth * focusTriggers.localScale)
        }
        width: Math.max(Math.round(Theme.lNotchMinWidth * focusTriggers.localScale), Math.min(Math.round(Theme.lNotchMaxWidth * focusTriggers.localScale), focusTriggers.leftContentImplicitWidth + Math.round(Theme.notchPadding * 2 * focusTriggers.localScale)))
        height: fmLeftHov.hovered ? focusTriggers.activeTriggerHeight : focusTriggers.idleTriggerHeight
        visible: ShellState.focusMode
        z: -1
        HoverHandler { id: fmLeftHov }
    }

    Item {
        id: fmCenterTrigger
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
        width: Math.max(Math.round(Theme.cNotchMinWidth * focusTriggers.localScale), Math.min(Math.round(Theme.cNotchMaxWidth * focusTriggers.localScale), focusTriggers.centerContentImplicitWidth + Math.round(Theme.notchPadding * 2 * focusTriggers.localScale)))
        height: fmCenterHov.hovered ? focusTriggers.activeTriggerHeight : focusTriggers.idleTriggerHeight
        visible: !SurfaceState.isTopExpanded
        z: -1
        HoverHandler { id: fmCenterHov; onHoveredChanged: Popups.dashboardTriggerHovered = hovered }
        TapHandler {
            onTapped: {
                Popups.closeAll()
                SurfaceState.open("top", "dashboard")
                Popups.dashboardPinned = true
            }
        }
    }

    Item {
        id: fmRightTrigger
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: PrefsService.isFloating ? Math.max(4, Math.round(PrefsService.floatingGap * focusTriggers.localScale)) : Math.round(Theme.borderWidth * focusTriggers.localScale)
        }
        width: Math.max(Math.round(Theme.rNotchMinWidth * focusTriggers.localScale), Math.min(Math.round(Theme.rNotchMaxWidth * focusTriggers.localScale), focusTriggers.rightContentImplicitWidth + Math.round(Theme.notchPadding * 2 * focusTriggers.localScale)))
        height: fmRightHov.hovered ? focusTriggers.activeTriggerHeight : focusTriggers.idleTriggerHeight
        visible: ShellState.focusMode
        z: -1
        HoverHandler { id: fmRightHov }
    }
}
