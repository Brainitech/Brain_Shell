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
import "../theme"
import "../services"
import "../"

Item {
    id: root

    property real localScale: 1.0

    // Geometry parameters (minimum 4px gap enforced on all sides, corner radius from Global Roundness)
    readonly property int gap:          Math.max(Math.round(4 * localScale), Math.round(PrefsService.floatingGap * localScale))
    readonly property int barHeight:    Math.round(PrefsService.floatingBarHeight * localScale)
    readonly property int cornerRadius: Math.round(Theme.cornerRadius * localScale)

    // Content width inputs passed from DynamicSurface
    property real leftContentWidth: 0
    property real centerContentWidth: 0
    property real rightContentWidth: 0

    // Morphing popup expansion inputs passed from DynamicSurface
    property bool isCenterExpanded: false
    property real centerExpandedWidth: 0
    property real centerExpandedHeight: 0

    property bool isRightExpanded: false
    property real rightExpandedWidth: 0
    property real rightExpandedHeight: 0

    // Idle Pill Dimensions
    readonly property real leftPillIdleWidth: Math.max(
        Math.round(Theme.lNotchMinWidth * localScale),
        Math.min(Math.round(Theme.lNotchMaxWidth * localScale), leftContentWidth + Math.round(Theme.notchPadding * 2 * localScale))
    )
    readonly property real leftPillIdleHeight: (ShellState.focusMode && !PrefsService.focusModeHoverExpand) ? 0 : barHeight

    readonly property real centerPillIdleWidth: Math.max(
        Math.round(Theme.cNotchMinWidth * localScale),
        Math.min(Math.round(Theme.cNotchMaxWidth * localScale), centerContentWidth + Math.round(Theme.notchPadding * 2 * localScale))
    )
    readonly property real centerPillIdleHeight: (ShellState.focusMode && !PrefsService.focusModeHoverExpand) ? 0 : barHeight

    readonly property real rightPillIdleWidth: Math.max(
        Math.round(Theme.rNotchMinWidth * localScale),
        Math.min(Math.round(Theme.rNotchMaxWidth * localScale), rightContentWidth + Math.round(Theme.notchPadding * 2 * localScale))
    )
    readonly property real rightPillIdleHeight: (ShellState.focusMode && !PrefsService.focusModeHoverExpand) ? 0 : barHeight

    // Active Pill Target Dimensions (attached morphing is permanent default)
    readonly property real centerTargetWidth: isCenterExpanded ? centerExpandedWidth : centerPillIdleWidth
    readonly property real centerTargetHeight: isCenterExpanded ? centerExpandedHeight : centerPillIdleHeight

    readonly property real rightTargetWidth: isRightExpanded ? rightExpandedWidth : rightPillIdleWidth
    readonly property real rightTargetHeight: isRightExpanded ? rightExpandedHeight : rightPillIdleHeight

    // Pill Dimension Properties with Smooth Morphing Behaviors
    property real leftPillWidth: leftPillIdleWidth
    property real leftPillHeight: leftPillIdleHeight
    Behavior on leftPillWidth  { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on leftPillHeight { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }

    property real centerPillWidth: centerTargetWidth
    property real centerPillHeight: centerTargetHeight
    Behavior on centerPillWidth  { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on centerPillHeight { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }

    property real rightPillWidth: rightTargetWidth
    property real rightPillHeight: rightTargetHeight
    Behavior on rightPillWidth  { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }
    Behavior on rightPillHeight { NumberAnimation { duration: Anim.transition; easing.type: Anim.outCubic } }

    // Positions (strictly computed from animated pill dimensions)
    readonly property real leftPillX: gap
    readonly property real leftPillY: gap

    readonly property real centerPillX: Math.round((root.width - centerPillWidth) / 2)
    readonly property real centerPillY: gap

    readonly property real rightPillX: Math.round(root.width - rightPillWidth - gap)
    readonly property real rightPillY: gap

    // ── Left Pill Capsule ───────────────────────────────────────────────────
    Rectangle {
        id: leftPillRect
        x: root.leftPillX
        y: root.leftPillY
        width: root.leftPillWidth
        height: root.leftPillHeight
        radius: root.cornerRadius
        color: Theme.background
        opacity: (ShellState.focusMode && !PrefsService.focusModeHoverExpand) ? 0.0 : 1.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
    }

    // ── Center Pill Capsule / Morphing Card ─────────────────────────────────
    Rectangle {
        id: centerPillRect
        x: root.centerPillX
        y: root.centerPillY
        width: root.centerPillWidth
        height: root.centerPillHeight
        radius: root.cornerRadius
        color: Theme.background
        opacity: (ShellState.focusMode && !PrefsService.focusModeHoverExpand && !root.isCenterExpanded) ? 0.0 : 1.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
    }

    // ── Right Pill Capsule / Morphing Card ──────────────────────────────────
    Rectangle {
        id: rightPillRect
        x: root.rightPillX
        y: root.rightPillY
        width: root.rightPillWidth
        height: root.rightPillHeight
        radius: root.cornerRadius
        color: Theme.background
        opacity: (ShellState.focusMode && !PrefsService.focusModeHoverExpand && !root.isRightExpanded) ? 0.0 : 1.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.transition; easing.type: Anim.globalCurve } }
    }
}
